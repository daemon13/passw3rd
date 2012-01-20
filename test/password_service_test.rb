require 'rubygems'
require 'test/unit'
require 'tmpdir'

require File.expand_path('../../lib/passw3rd.rb',  __FILE__)

class PasswordServiceTest < Test::Unit::TestCase
  def setup
    @random_string = sudorandumb
  end

  def setup_sandbox(path = Dir.tmpdir)
    ::Passw3rd::PasswordService.key_file_dir = path
    ::Passw3rd::PasswordService.password_file_dir = path
    ::Passw3rd::PasswordService.create_key_iv_file
  end

  def test_detect_cipher
    ::Passw3rd::PasswordService.cipher_name = ::Passw3rd::APPROVED_CIPHERS.last
    setup_sandbox

    enc = ::Passw3rd::PasswordService.encrypt(@random_string)
    dec = ::Passw3rd::PasswordService.decrypt(enc)

    ::Passw3rd::PasswordService.cipher_name = ::Passw3rd::APPROVED_CIPHERS.first

    assert_raise(OpenSSL::Cipher::CipherError) do 
      ::Passw3rd::PasswordService.decrypt(enc)    
    end
  end
  
  def test_enc_dec
    setup_sandbox
    enc = ::Passw3rd::PasswordService.encrypt(@random_string)
    dec = ::Passw3rd::PasswordService.decrypt(enc)
    
    assert_equal(@random_string, dec)
  end

  def test_enc_raise_on_blank_password
    assert_raise(ArgumentError) { ::Passw3rd::PasswordService.encrypt("") }
  end

  def test_enc_raise_on_nil_password
    assert_raise(ArgumentError) { ::Passw3rd::PasswordService.encrypt(nil) }
  end

  def test_set_and_get_password
    setup_sandbox
    password_file = ::Passw3rd::PasswordService.write_password_file(@random_string, "test")
    decrypted = ::Passw3rd::PasswordService.get_password("test")
    assert_equal(@random_string, decrypted)
  end

  def test_set_and_get_password_custom_dir
    dir = "#{Dir.tmpdir}/#{sudorandumb}"
    ::Passw3rd::PasswordService.password_file_dir = dir
    ::Passw3rd::PasswordService.key_file_dir = dir

    assert_passw3rd_cycle(dir)
  end  

  def test_with_env_vars
    ::Passw3rd::PasswordService.key_file_dir = nil
    ::Passw3rd::PasswordService.password_file_dir = nil
    dir = "#{Dir.tmpdir}/#{sudorandumb}"
    ENV['passw3rd-password_file_dir'] = dir
    ENV['passw3rd-key_file_dir'] = dir

    assert_passw3rd_cycle(dir)
  end

  def test_configure_with_block
   ::Passw3rd::PasswordService.configure do |c|
      c.password_file_dir = Dir.tmpdir
      c.key_file_dir = Dir.tmpdir
      c.cipher_name = ::Passw3rd::APPROVED_CIPHERS.first
    end
    assert_equal(::Passw3rd::PasswordService.password_file_dir, Dir.tmpdir)
    assert_equal(::Passw3rd::PasswordService.cipher_name, ::Passw3rd::APPROVED_CIPHERS.first)
  end
  
  def sudorandumb
    Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by{rand}.join)
  end

  def assert_passw3rd_cycle dir
    FileUtils.mkdir_p(dir)
    path = ::Passw3rd::PasswordService.create_key_iv_file

    id = sudorandumb
    password_file_path = ::Passw3rd::PasswordService.write_password_file(@random_string, "test#{id}")
    assert_match(Regexp.new(dir), password_file_path)
    
    decrypted = ::Passw3rd::PasswordService.get_password("test#{id}")
    assert_equal(@random_string, decrypted)

    FileUtils.rm_rf(dir)
  end


end
