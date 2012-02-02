![Build status](https://secure.travis-ci.org/oreoshake/passw3rd.png)

It's only failing because it can't find the system ruby.  If you have a solution, checkout bin/passw3rd please :)

It will still work on your machine.

Introduction
------------------------------------------------------------------------------

This is a collection of encryption libraries intended to encrypt and store
passwords outside of source code.

Some advantages of keeping credentials out of source code are:

1. Credentials are not passed around when source code is shared.
2. Unintentional exposure of source code does not reveal credentials.
3. Read-access to source code can be much more permissive.
4. Source code can be checked into version control systems without concern
   for exposure of credentials.
5. It is easier to change credentials without having to worry about changing
   all instances.
6. Leaving credentials in source code leads to poor password management in
   general. If changing a credential requires you to change code, you are less
   likely to want to do it. 


Status
------------------------------------------------------------------------------

This project is IN PROGRESS. File bugs and feature requests.

Examples
------------------------------------------------------------------------------
Command line use
 
    Generate key/iv in ~/ by default
 
        $ passw3rd -g
        generated keys in /Users/user
 
        $ passw3rd -g ~/Desktop/
        generated keys in /Users/user/Desktop/
 
    Create a password file
 
        $ passw3rd -e foobar_app
        Enter the password: 
        Wrote password to /Users/neilmatatall/foobar_app
        $ passw3rd -e foobar_app -p ~/Desktop/
        Enter the password: 
        Wrote password to /Users/neilmatatall/Desktop/foobar_app
 
    Read a password file
 
        $ passw3rd -d foobar_app
        The password is: asdf
        $ passw3rd -d foobar_app -p ~/Desktop/
        The password is: asdf
------------------------------------------------------------------------------

Key rotation: simple
------------------------------------------------------------------------------

    $ rake rotate_keys[~/passwords,~/passwords,aes-256-cbc]
  
------------------------------------------------------------------------------
Ruby on Rails config/database.yml
 
Example configuration in boot.rb:

    ENV['passw3rd-cipher_name'] = 'aes-256-cbc'
    if %w{production staging}.include? ENV['RAILS_ENV']
      ENV['passw3rd-password_file_dir'] = File.expand_path('../../passwords/production', __FILE__)
      ENV['passw3rd-key_file_dir'] = File.expand_path('../../passwords/production', __FILE__)
    else
      ENV['passw3rd-password_file_dir'] = File.expand_path('../../passwords', __FILE__)
      ENV['passw3rd-key_file_dir'] = File.expand_path('../../passwords', __FILE__)
    end	

Then remove passwords from config files and source code
 
    Before:
 
    development:
      adapter: mysql
      database: rails_development
      username: root
      password: my super secret password
 
 
    After:
 
    development:
      adapter: mysql
      database: rails_development
      username: root
      password: <%= PasswordService.get_password('foobar_app') -%>
 
------------------------------------------------------------------------------
OpenSSL command line
 
    $ openssl enc -e -aes-256-cbc -K `cat ~/.passw3rd-encryptionKey`  -iv `cat ~/.passw3rd-encryptionIV` -in README.md -out test.out
    $ openssl enc -d -aes-256-cbc -K `cat ~/.passw3rd-encryptionKey`  -iv `cat ~/.passw3rd-encryptionIV` -out README.md -in test.out


License
------------------------------------------------------------------------------

License: MIT (see LICENSE file)


Credits
------------------------------------------------------------------------------

Copyright 2010, YELLOWPAGES.COM LLC
Development by Neil Matatall <neil.matatall@gmail.com>

