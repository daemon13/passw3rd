source :rubygems

gem "jruby-openssl", :platform => :jruby

group :development, :test do
  gem 'rake'
  gem 'guard'
  gem 'guard-test'
  gem 'guard-rspec'
  gem 'rspec'
  gem 'guard-cucumber'
  gem 'cucumber'
  gem 'aruba'
  
  if RUBY_PLATFORM.downcase.include?("darwin")
    gem "rb-fsevent"
    gem "growl"
  end
end
