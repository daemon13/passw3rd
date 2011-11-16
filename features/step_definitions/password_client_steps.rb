Given /^I have configured passw3rd to work in a sandbox$/ do
  dir = File.join(Dir.tmpdir, 'passw3rd')
  FileUtils.rm_rf(dir)
  FileUtils.mkdir_p(dir)
  ENV['passw3rd-password_file_dir'] = dir
  ENV['passw3rd-key_file_dir'] = dir
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
   
Given /^I set the cipher to "([^"]*)"$/ do |arg1|
  ENV['passw3rd-cipher_name'] = arg1
end

Given /^I remember the encrypted value for the file "([^"]*)"$/ do |file|
  @password = ::Passw3rd::PasswordService.send(:read_file, File.join(ENV['passw3rd-password_file_dir'], file))
end

When /^I rotate my keys$/ do
  ::Passw3rd::PasswordService.rotate_keys
end

Then /^the encrypted password in the file "([^"]*)" should have changed$/ do |file|
  @password.should_not == ::Passw3rd::PasswordService.send(:read_file, File.join(ENV['passw3rd-password_file_dir'], file))
end

Then /^the keys should be rotated$/ do
  new_keys = ::Passw3rd::PasswordService.load_key
  new_keys.should_not == @keys
end

When /^I change the cipher for my password files from "(.*)" to "(.*)"$/ do |from, to|
  ::Passw3rd::PasswordService.rotate_keys(:password_file_dir => ENV['passw3rd-password_file_dir'], :key_file_dir => ENV['passw3rd-key_file_dir'], cipher: from, new_ciphter: to)
end

Then /^the keys should be (\d+) bits long$/ do |x|
  keys = ::Passw3rd::PasswordService.load_key
  keys[:key].unpack("H*")[0].length.should == x.to_i/4
end

Given /^I remember my keys$/ do
  @keys = ::Passw3rd::PasswordService.load_key 
end
