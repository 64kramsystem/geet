# frozen_string_literal: true

require "spec_helper"

describe Geet::Git::Repository do
  describe "API token handling" do
    it "allows the token to be omitted when authentication is not required" do
      api_token = ENV.delete("GH_TOKEN")

      expect { described_class.new(api_token_required: false) }.not_to raise_error
    ensure
      ENV["GH_TOKEN"] = api_token if api_token
    end

    it "requires the token by default" do
      api_token = ENV.delete("GH_TOKEN")

      expect { described_class.new }.to raise_error("GH_TOKEN not set!")
    ensure
      ENV["GH_TOKEN"] = api_token if api_token
    end
  end
end
