require File.expand_path('../../../lib/passw3rd',  __FILE__)
ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"

ENV['passw3rd-password_file_dir'] = File.join(Dir.getwd, 'tmp')
ENV['passw3rd-key_file_dir'] = File.join(Dir.getwd, 'tmp')
