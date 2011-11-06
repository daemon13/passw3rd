Given /^I have configured passw3rd to work in a sandbox$/ do
  ::Passw3rd::PasswordService.configure do |c|
    c.password_file_dir = Dir.tmpdir
    c.key_file_dir = Dir.tmpdir
    c.cipher_name = ::Passw3rd::APPROVED_CIPHERS.first
  end
end

Then /^my keys should be generated$/ do
  File.exists?(::Passw3rd::PasswordService.key_path).should be_true
  File.exists?(::Passw3rd::PasswordService.iv_path).should be_true
end

Given /^I have generated keys$/ do
  ::Passw3rd::PasswordService.create_key_iv_file
end

Then /^a password file for "([^"]*)" is created$/ do |file_name|
  # mv to helper
  path = File.join(::Passw3rd::PasswordService.password_file_dir, file_name)
  File.exists?(path).should be_true
end

Then /^the password file named "([^"]*)" should not contain "([^"]*)"$/ do |file_name, content|
  # mv to helper
  path = File.join(::Passw3rd::PasswordService.password_file_dir, file_name)  
  check_file_content(path, content, false)
end

Given /^I have a password file named "([^"]*)"(?: for the password "([^"]*)")?$/ do |file_name, password|
  password ||= "passw3rd"
  path = ::Passw3rd::PasswordService.write_password_file(password, file_name)
end

When /^I generate a password file named "([^"]*)"(?: for the password "([^"]*)")?$/ do |file_name, password|
  password ||= "passw3rd"
  steps %Q{
    When I run `passw3rd -e #{file_name}` interactively
    And I type "#{password}"
    And the output should contain "Wrote password to"
  }
end

When /^I generate keys$/ do
  steps %Q{
    When I successfully run `passw3rd -g`
  }
end

When /^I decrypt the password file named "([^"]*)"$/ do |file_name|
  steps %Q{
   When I successfully run `passw3rd -d #{file_name}`
  }
end
   


