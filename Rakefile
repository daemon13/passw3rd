require "rake"
require "rake/testtask"
require "rspec/core/rake_task"
require "passw3rd"
require "benchmark"
require "tmpdir"


desc "Default: run unit tests."
task :default => [:test, :spec, :benchmark]

desc "Test the passw3rd gem"
Rake::TestTask.new(:test) do |t|
  t.libs << "lib"
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose    = true
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.fail_on_error = false
  t.verbose = true
end

task :benchmark do
  n = 1000
  password = "passw3rd"
  
  ::Passw3rd::PasswordService.configure do |c|
    c.password_file_dir = Dir.tmpdir
    c.key_file_dir = Dir.tmpdir
    c.cipher_name = "aes-256-cbc"
  end

  Benchmark.bmbm do |x|
    x.report("generate a key, write the encrypted version of #{password} a file, read the password #{n} times") do
      n.times do
        ::Passw3rd::PasswordService.create_key_iv_file
        ::Passw3rd::PasswordService.write_password_file(password, "test")
        ::Passw3rd::PasswordService.get_password("test")
      end
    end
  end
end

task :rotate_keys, :password_file_dir, :key_file_dir, :cipher do |t, args|
  Passw3rd::PasswordService.rotate_keys(args)
end

task :change_cipher, :password_file_dir, :key_file_dir, :cipher, :new_cipher do |t, args|
  Passw3rd::PasswordService.rotate_keys(args)
end