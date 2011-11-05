require 'open-uri'

module Passw3rd
  class PasswordService
    KEY_FILE = "/.passw3rd-encryptionKey"
    IV_FILE = "/.passw3rd-encryptionIV"
    APPROVED_CIPHERS = %w{aes-128-cbc aes-256-cbc aes-128-cfb aes-256-cfb}

    class << self
      attr_writer :password_file_dir
      def password_file_dir
        @password_file_dir || ENV.fetch("HOME")
      end

      attr_writer :key_file_dir
      def key_file_dir
        @key_file_dir || ENV.fetch("HOME")
      end

      def cipher_name= (cipher_name)
        raise "Hey man, you can only use #{APPROVED_CIPHERS}, you supplied #{cipher_name}" if cipher_name.nil? || !APPROVED_CIPHERS.include?(cipher_name)
        @cipher_name = cipher_name
      end

      def cipher_name
        @cipher_name || 'aes-256-cbc'
      end
    end

    def self.configure(&block)
      instance_eval &block
    end

    def self.get_password (password_file, key_path = key_file_dir)
      uri = _parse_uri(password_file)
      encoded_password = Base64.decode64(open(uri) { |f| f.read })
      decrypt(encoded_password, key_path)
    end

    def self.write_password_file(password, output_path, key_path = key_file_dir)
      enc_password = encrypt(password, key_path)
      base64pw = Base64.encode64(enc_password) 
      path = File.join(password_file_dir, output_path)
      open(path, 'w') { |f| f.write base64pw }
      path
    end

    def self.encrypt(password, key_path = key_file_dir)
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

    def self.decrypt(cipher_text, key_path = key_file_dir)
      cipher = cipher_setup(:decrypt, key_path)
      begin
        d = cipher.update(cipher_text)
        d << cipher.final
      rescue OpenSSL::Cipher::CipherError => err
        puts "Couldn't decrypt password.  Are you using the right keys (#{key_path})?"
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

    def self.create_key_iv_file(path=nil)
      unless path
        path = ::Passw3rd::PasswordService.key_file_dir || ENV['HOME']
      end    

      # d'oh!
      cipher = OpenSSL::Cipher::Cipher.new(::Passw3rd::PasswordService.cipher_name)
      iv = cipher.random_iv
      key = cipher.random_key

      begin
        File.open(path + KEY_FILE, 'w') {|f| f.write(key.unpack("H*").join) }
        File.open(path + IV_FILE, 'w') {|f| f.write(iv.unpack("H*").join) }
      rescue
        puts "Couldn't write key/IV to #{path}\n"
        raise $!
      end
      path
    end

    protected
    
    def self.load_key(path=nil) 
      if path.nil?
        path = ::Passw3rd::PasswordService.key_file_dir
      end

      begin
        key = IO.readlines(File.expand_path(path + KEY_FILE))[0]
        iv = IO.readlines(File.expand_path(path + IV_FILE))[0]
      rescue Errno::ENOENT
        puts "Couldn't read key/iv from #{path}.  Have they been generated?\n"
        raise $!
      end

      {:key => [key].pack("H*"), :iv => [iv].pack("H*")}
    end    

    def self.cipher_setup(method, key_path)
      pair = self.load_key(key_path)
      cipher = OpenSSL::Cipher::Cipher.new(cipher_name)
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
  end
end
