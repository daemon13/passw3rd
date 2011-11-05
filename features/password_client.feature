@aruba @announce
Feature: Passw3rd command line client
  As an admininstrator
  With proper access to password files
  I want to manage keys and password files
  
  Scenario: generate keys
    When I generate keys
    Then my keys should be generated
    
  Scenario: encrypt a file
    Given I have generated keys
    When I generate a password file named "test1"
    Then a password file for "test1" is created
    
  Scenario: decrypt a file
    Given I have generated keys
    And I have a password file named "test2" for the password "passw3rd"
    When I decrypt the password file named "test2"
    Then the output should contain "The password is: passw3rd"
    
  Scenario: integration test
    When I generate keys
    And I generate a password file named "test3"
    And I decrypt the password file named "test3"
    