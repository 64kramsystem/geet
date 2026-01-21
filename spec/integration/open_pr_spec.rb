# frozen_string_literal: true

require "spec_helper"

require_relative "../../lib/geet/git/repository"
require_relative "../../lib/geet/services/open_pr"

describe Geet::Services::OpenPr do
  let(:git_client) { Geet::Utils::GitClient.new }
  let(:repository) { Geet::Git::Repository.new(git_client: git_client) }
  let(:owner) { "donaldduck" }
  let(:branch) { "mybranch" }

  context "with github.com" do
    let(:repository_name) { "testrepo_upstream" }

    it "should open the PR for the current branch" do
      allow(git_client).to receive(:current_branch).and_return(branch)
      allow(git_client).to receive(:remote).with(no_args).and_return("git@github.com:#{owner}/#{repository_name}")

      expected_pr_number = 3
      expected_output = <<~STR
        Finding PR with head (#{owner}:#{branch})...
      STR

      expect {
        service_instance = described_class.new(repository, git_client: git_client)

        expect(service_instance).to receive(:open_file_with_default_application).with("https://github.com/#{owner}/#{repository_name}/pull/#{expected_pr_number}") do
          # do nothing; just don't open the browser
        end

        service_result = VCR.use_cassette("github_com/open_pr") do
          service_instance.execute
        end

        expect(service_result.number).to eql(expected_pr_number)
      }.to output(expected_output).to_stdout
    end

  end # context 'with github.com'
end
