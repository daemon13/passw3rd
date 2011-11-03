require "rake"
require "rake/testtask"
require "rspec/core/rake_task"
require "passw3rd"
require "benchmark"


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
end

task :benchmark do
  n = 1000
  password = "passw3rd"
  
  ::Passw3rd::PasswordService.configure do |c|
    c.password_file_dir = "/tmp/"
    c.cipher_name = "aes-256-cbc"
  end

  Benchmark.bmbm do |x|
    x.report("generate a key, write the encrypted version of #{password} a file, read the password #{n} times") do
      n.times do
        ::Passw3rd::KeyLoader.create_key_iv_file('/tmp')
        ::Passw3rd::PasswordService.write_password_file(password, "test")
        ::Passw3rd::PasswordService.get_password("test")
      end
    end
  end
end