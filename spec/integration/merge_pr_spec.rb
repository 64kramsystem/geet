# frozen_string_literal: true

require "spec_helper"

require_relative "../../lib/geet/git/repository"
require_relative "../../lib/geet/services/merge_pr"

# Currently disabled: it requires updates following the addition of the automatic removal of the local
# branch.
# Specifically, `GitClient#remote_branch_gone?` needs to be handled, since it returns the current
# branch, while it's supposed to return
#
describe Geet::Services::MergePr do
  let(:git_client) { Geet::Utils::GitClient.new }
  let(:repository) { Geet::Git::Repository.new(git_client: git_client) }
  let(:owner) { "donaldduck" }
  let(:branch) { "mybranch" }
  let(:main_branch) { "main" }

  before :each do
    expect(git_client).to receive(:fetch).twice
    expect(git_client).to receive(:push)
    expect(git_client).to receive(:cherry).with("HEAD", head: :main_branch).and_return([])
    expect(git_client).to receive(:remote_branch_gone?).and_return(true)
    expect(git_client).to receive(:checkout).with(main_branch)
    expect(git_client).to receive(:rebase)
    expect(git_client).to receive(:delete_branch).with("mybranch", force: false)
  end

  context "with github.com" do
    let(:repository_name) { "testrepo_upstream" }

    it "should merge the PR for the current branch" do
      allow(git_client).to receive(:current_branch).and_return(branch)
      allow(git_client).to receive(:main_branch).and_return(main_branch)
      allow(git_client).to receive(:remote).with(no_args).and_return("git@github.com:#{owner}/#{repository_name}")

      expected_pr_number = 1
      expected_output = <<~STR
        Finding PR with head (#{owner}:#{branch})...
        Merging PR ##{expected_pr_number}...
        Fetching repository...
        Checking out #{main_branch}...
        Rebasing...
        Deleting local branch mybranch...
      STR

      actual_output = StringIO.new

      service_result = VCR.use_cassette("github_com/merge_pr") do
        described_class.new(repository, out: actual_output, git_client: git_client).execute
      end

      actual_pr_number = service_result.number

      expect(actual_output.string).to eql(expected_output)
      expect(actual_pr_number).to eql(expected_pr_number)
    end

    it "should merge the PR for the current branch, with branch deletion" do
      allow(git_client).to receive(:current_branch).and_return(branch)
      allow(git_client).to receive(:main_branch).and_return(main_branch)
      allow(git_client).to receive(:remote).with(no_args).and_return("git@github.com:#{owner}/#{repository_name}")

      expected_pr_number = 2
      expected_output = <<~STR
        Finding PR with head (#{owner}:#{branch})...
        Merging PR ##{expected_pr_number}...
        Deleting remote branch #{branch}...
        Fetching repository...
        Checking out #{main_branch}...
        Rebasing...
        Deleting local branch mybranch...
      STR

      actual_output = StringIO.new

      service_result = VCR.use_cassette("github_com/merge_pr_with_branch_deletion") do
        described_class.new(repository, out: actual_output, git_client: git_client).execute(delete_branch: true)
      end

      actual_pr_number = service_result.number

      expect(actual_output.string).to eql(expected_output)
      expect(actual_pr_number).to eql(expected_pr_number)
    end
  end # context 'with github.com'

  context "with gitlab.com" do
    let(:repository_name) { "testproject" }

    it "should merge the PR for the current branch" do
      allow(git_client).to receive(:current_branch).and_return(branch)
      allow(git_client).to receive(:main_branch).and_return(main_branch)
      allow(git_client).to receive(:remote).with(no_args).and_return("git@gitlab.com:#{owner}/#{repository_name}")

      expected_pr_number = 4
      expected_output = <<~STR
        Finding PR with head (#{owner}:#{branch})...
        Merging PR ##{expected_pr_number}...
        Fetching repository...
        Checking out #{main_branch}...
        Rebasing...
        Deleting local branch mybranch...
      STR

      actual_output = StringIO.new

      service_result = VCR.use_cassette("gitlab_com/merge_pr") do
        described_class.new(repository, out: actual_output, git_client: git_client).execute
      end

      actual_pr_number = service_result.number

      expect(actual_output.string).to eql(expected_output)
      expect(actual_pr_number).to eql(expected_pr_number)
    end
  end # context 'with gitlab.com'
end
