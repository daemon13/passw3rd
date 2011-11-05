Given /^I have configured passw3rd to work in a sandbox$/ do
  ::Passw3rd::PasswordService.configure do |c|
    c.password_file_dir = Dir.tmpdir
    c.key_file_dir = Dir.tmpdir
    c.cipher_name = "aes-256-cbc"
  end
end

Then /^my keys should be generated$/ do
  File.exists?(::Passw3rd::PasswordService.key_path).should be_true
  File.exists?(::Passw3rd::PasswordService.iv_path).should be_true
end

Given /^I have generated keys$/ do
  ::Passw3rd::PasswordService.create_key_iv_file
end

Then /^a password file for "([^"]*)" is created$/ do |name|
  File.exists?(File.join(::Passw3rd::PasswordService.password_file_dir, name)).should be_true
end

Given /^I have a password file named "([^"]*)"(?: for the password "([^"]*)")?$/ do |file_name, password|
  password ||= "passw3rd"
  path = ::Passw3rd::PasswordService.write_password_file(password, file_name)
end

When /^I generate a password file named "([^"]*)(?: for the password "([^"]*)")?"$/ do |file_name, password|
  password ||= "passw3rd"
  steps %Q{
    When I run `passw3rd -e #{file_name}` interactively
    And I type "#{password}"  
  }
end

When /^I generate keys$/ do
  steps %Q{
    When I run `passw3rd -g`
  }
end

When /^I decrypt the password file named "([^"]*)"$/ do |file_name|
  steps %Q{
   When I run `passw3rd -d #{file_name}`
  }
end
   


