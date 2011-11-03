require "rake"
require "rake/testtask"
require "rspec/core/rake_task"

desc "Default: run unit tests."
task :default => [:test, :spec]

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