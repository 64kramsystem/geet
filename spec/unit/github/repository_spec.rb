# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Geet::Github::Repository do
  let(:api_interface) { instance_double(Geet::Github::ApiInterface) }
  let(:response) do
    {
      "full_name" => "donald/geet",
      "html_url" => "https://github.com/donald/geet",
      "ssh_url" => "git@github.com:donald/geet.git",
    }
  end

  it "creates a private repository for the authenticated user" do
    expect(api_interface).to receive(:send_request).with("/user/repos", data: {name: "geet", private: true}).and_return(response)
    repository = described_class.create("geet", "private", api_interface)
    expect([repository.full_name, repository.html_url, repository.ssh_url]).to eq(["donald/geet", "https://github.com/donald/geet", "git@github.com:donald/geet.git"])
  end

  it "creates a public repository for the authenticated user" do
    expect(api_interface).to receive(:send_request).with("/user/repos", data: {name: "geet", private: false}).and_return(response)
    described_class.create("geet", "public", api_interface)
  end

  it "requests a named fork" do
    expect(api_interface).to receive(:send_request).with("/repos/upstream/project/forks", data: {name: "geet"}).and_return(response)
    described_class.fork("upstream/project", "geet", api_interface)
  end

  it "fetches a repository" do
    expect(api_interface).to receive(:send_request).with("/repos/donald/geet").and_return(response)
    expect(described_class.fetch("donald/geet", api_interface).full_name).to eq("donald/geet")
  end

  it "updates the default branch" do
    expect(api_interface).to receive(:send_request).with("/repos/donald/geet", data: {default_branch: "topic"}, http_method: :patch)
    described_class.new(response, api_interface).update_default_branch("topic")
  end
end
