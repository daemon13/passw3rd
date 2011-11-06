@aruba
Feature: Passw3rd command line client
  As an admininstrator
  With proper access to password files
  I want to manage keys and password files
  # extract the test[n] garbage
  
  Scenario: generate keys
    When I generate keys
    Then my keys should be generated
    
  Scenario: encrypt a file
    Given I have generated keys
    When I generate a password file named "test1" for the password "supar sekret"
    Then a password file for "test1" is created
    Then the password file named "test1" should not contain "supar sekret"
    
  Scenario: decrypt a file
    Given I have generated keys
    And I have a password file named "test2" for the password "passw3rd"
    When I decrypt the password file named "test2"
    Then the output should contain "The password is: passw3rd"
    
  Scenario: integration test
    When I generate keys
    And I generate a password file named "test3" for the password "Peyton Manning is the greatest quarterback ever."
    And I decrypt the password file named "test3"
    Then the output should contain "The password is: Peyton Manning is the greatest quarterback ever."
    
  Scenario: rotate keys
    Given I have generated keys
    And I have a password file named "test4" for the password "passw3rd"
    And I remember the encrypted value for the file "test4"
    When I rotate my keys
    Then the encrypted password in the file "test4" should have changed
    And the keys should be rotated

  Scenario: change cipher
    Given I set the cipher to "aes-128-cbc"  
    And I have generated keys
    And I have a password file named "test5" for the password "passw3rd"
    And I remember the encrypted value for the file "test5"
    When I set the cipher to "aes-256-ofb"
    And I change the cipher for my password files
    Then the encrypted password in the file "test5" should have changed
    And the keys should be 256 bits long
