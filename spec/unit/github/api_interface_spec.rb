# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

describe Geet::Github::ApiInterface do
  describe "authentication" do
    let(:request_url) { "https://api.github.com/repos/owner/repository/issues" }

    it "sends an unauthenticated request when no token is available" do
      request = stub_request(:get, request_url)
        .with { |actual_request| !actual_request.headers.key?("Authorization") }
        .to_return(status: 200, body: "[]")

      described_class.new(nil, repo_path: "owner/repository").send_request("issues")

      expect(request).to have_been_requested.once
    end

    it "authenticates the request when a token is available" do
      authorization = "Basic #{Base64.strict_encode64(":token")}"
      request = stub_request(:get, request_url)
        .with(headers: {"Authorization" => authorization})
        .to_return(status: 200, body: "[]")

      described_class.new("token", repo_path: "owner/repository").send_request("issues")

      expect(request).to have_been_requested.once
    end
  end
end
