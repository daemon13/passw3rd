require 'open-uri'

module Passw3rd
  KEY_FILE = ".passw3rd-encryptionKey"
  IV_FILE = ".passw3rd-encryptionIV"
  # more preferred ciphers first
  APPROVED_CIPHERS = %w{aes-256-cbc aes-256-cfb aes-128-cbc aes-128-cfb}
  
  class PasswordService

    class << self
      attr_writer :password_file_dir
      def password_file_dir
        @password_file_dir || ENV['passw3rd-password_file_dir'] || Dir.getwd
      end

      attr_writer :key_file_dir
      def key_file_dir
        @key_file_dir || ENV['passw3rd-key_file_dir'] || Dir.getwd
      end

      def cipher_name= (cipher_name)
        raise "Hey man, you can only use #{APPROVED_CIPHERS}, you supplied #{cipher_name}" if cipher_name.nil? || !APPROVED_CIPHERS.include?(cipher_name)
        @cipher_name = ENV['passw3rd-cipher_name'] || cipher_name
      end

      def cipher_name
        defined?(@cipher_name) ? @cipher_name : APPROVED_CIPHERS.first
      end
    end

    def self.configure(&block)
      instance_eval &block
    end

    def self.get_password (password_file, options = {:key_path => self.key_file_dir, :force => true})
      uri = _parse_uri(password_file)
      encoded_password = read_file(uri)
      decrypt(encoded_password, options[:key_path])
    rescue => e
      raise e, "Could not decrypt passw3rd file #{password_file} - #{e}" if options[:force]
    end

    def self.write_password_file(password, output_path, key_path = self.key_file_dir)
      enc_password = encrypt(password, key_path)
      base64pw = Base64.encode64(enc_password) 
      path = File.join(password_file_dir, output_path)
      write_file(path, base64pw)
      path
    end

    def self.encrypt(password, key_path = self.key_file_dir)
      raise ArgumentError, "password cannot be blank" if password.to_s.empty?

      cipher = cipher_setup(:encrypt, key_path)
      begin
        e = cipher.update(password)
        e << cipher.final
      rescue OpenSSL::Cipher::CipherError => err
        puts "Couldn't encrypt password."
        raise err
      end
    end

    def self.decrypt(cipher_text, key_path = self.key_file_dir)
      begin
        do_decrypt(cipher_text, key_path, cipher_name)
      rescue StandardError => err
        puts "Couldn't decrypt password #{cipher_text}.  Are you using the right keys (#{key_path})?"
        puts "Trying other ciphers..."
        APPROVED_CIPHERS.each do | cipher |
          begin
            if do_decrypt(cipher_text, key_path, cipher)
              puts <<-EOS
                I wasn't able to decrypt using the provided setup, but I was able
                to decrypt the files use the #{cipher} cipher.

                Add the following config (for rails, in boot.rb)

                ENV['passw3rd-cipher_name'] = '#{cipher}'

                OR

                ::Passw3rd::PasswordService.configure do |c|
                  c.cipher_name = '#{cipher}'
                end
              EOS
            end
          rescue Exception => e
            # long hair don't care
          end
        end

        raise err
      end
    end

    def self.rotate_keys(args = {})
      unless args.empty?
        ::Passw3rd::PasswordService.configure do |c|
          c.password_file_dir = args[:password_file_dir]
          c.key_file_dir = args[:key_file_dir]
          c.cipher_name = args[:cipher]
        end
      end

      passwords = []

      Dir.foreach(::Passw3rd::PasswordService.password_file_dir) do |passw3rd_file|
        next if %w{. ..}.include?(passw3rd_file) || passw3rd_file =~ /\A\.passw3rd/
        puts "Rotating #{passw3rd_file}"
        passwords << {:clear_password => ::Passw3rd::PasswordService.get_password(passw3rd_file), :file => passw3rd_file}
      end

      ::Passw3rd::PasswordService.cipher_name = args[:new_cipher] if args[:new_cipher]

      path = self.create_key_iv_file
      puts "Wrote new keys to #{path}"

      passwords.each do |password|
        full_path = File.join(::Passw3rd::PasswordService.password_file_dir, password[:file])
        ::Passw3rd::PasswordService.write_password_file(password[:clear_password], password[:file])    
        puts "Wrote new password to #{full_path}"
      end
    end

    def self.create_key_iv_file(path = nil)
      unless path
        path = ::Passw3rd::PasswordService.key_file_dir
      end    

      # d'oh!
      cipher = OpenSSL::Cipher::Cipher.new(::Passw3rd::PasswordService.cipher_name)
      iv = cipher.random_iv
      key = cipher.random_key

      begin
        File.open(self.key_path(path), 'w') {|f| f.write(key.unpack("H*").join) }
        File.open(self.iv_path(path), 'w') {|f| f.write(iv.unpack("H*").join) }
      rescue
        puts "Couldn't write key/IV to #{path}\n"
        raise $!
      end
      path
    end
    
    def self.key_path(path= self.key_file_dir)
      File.join(path || self.key_file_dir, KEY_FILE)
    end
    
    def self.iv_path(path = ::Passw3rd::PasswordService.key_file_dir)
      File.join(path || self.key_file_dir, IV_FILE)
    end      

    protected
    
    def self.load_key(path = ::Passw3rd::PasswordService.key_file_dir)
      begin
        key = IO.readlines(File.expand_path(self.key_path(path)))[0]
        iv = IO.readlines(File.expand_path(self.iv_path(path)))[0]
      rescue StandardError => e
        puts "Couldn't read key/iv from #{self.key_path(path)}.  Have they been generated?\n"
        raise e
      end

      {:key => [key].pack("H*"), :iv => [iv].pack("H*")}
    end    

    def self.cipher_setup(method, key_path, cipher_override = nil)
      pair = self.load_key(key_path)
      cipher = OpenSSL::Cipher::Cipher.new(cipher_override || cipher_name)
      cipher.send(method)
      cipher.key = pair[:key]
      cipher.iv = pair[:iv]
      cipher
    end

    def self._parse_uri password_file
      unless (password_file =~ URI::regexp(['ftp', 'http', 'https', 'file'])).nil?
        URI.parse(password_file)
      else
        File.join(password_file_dir, password_file)
      end
    end

    def self.read_file uri
      Base64.decode64(open(uri) { |f| f.read })
    end

    def self.write_file path, value
      open(path, 'w') { |f| f.write value }
    end

    def self.do_decrypt(cipher_text, key_path, cipher)
      cipher = cipher_setup(:decrypt, key_path, cipher)
      d = cipher.update(cipher_text)
      d << cipher.final
    end
  end
end
