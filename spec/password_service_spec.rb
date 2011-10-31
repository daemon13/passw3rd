require 'spec_helper'

describe ::Passw3rd::PasswordService do 
  describe "#_parse_uri" do
    it "detects uris" do
      ::Passw3rd::PasswordService._parse_uri("http://example.com").should be_is_a URI::HTTP
    end

    it "falls back to a file path" do
      URI.should_not_receive(:parse)
      ::Passw3rd::PasswordService._parse_uri("/some/file/some/where/over/the/rainbow").should be_is_a String
    end
  end
end