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

    context "when the response is Not Found" do
      before do
        stub_request(:get, request_url).to_return(status: 404, body: {message: "Not Found"}.to_json)
      end

      it "hints at the missing token when no token is available" do
        expect {
          described_class.new(nil, repo_path: "owner/repository").send_request("issues")
        }.to raise_error(Geet::Shared::HttpError, "Not Found (GH_TOKEN is not set; private repositories require it)") { |error|
          expect(error.code).to eq(404)
        }
      end

      it "doesn't hint at the token when one is available" do
        expect {
          described_class.new("token", repo_path: "owner/repository").send_request("issues")
        }.to raise_error(Geet::Shared::HttpError, "Not Found")
      end
    end
  end
end
