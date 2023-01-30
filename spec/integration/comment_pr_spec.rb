# frozen_string_literal: true

require 'spec_helper'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/comment_pr'

describe Geet::Services::CommentPr do
  let(:git_client) { Geet::Utils::GitClient.new }
  let(:repository) { Geet::Git::Repository.new(git_client: git_client) }
  let(:owner) { 'donaldduck' }
  let(:branch) { 'mybranch' }
  let(:comment) { 'this is a programmatically added comment' }

  context 'with github.com' do
    let(:repository_name) { 'testrepo_upstream' }

    it 'should add a comment to the PR for the current branch' do
      allow(git_client).to receive(:current_branch).and_return(branch)
      allow(git_client).to receive(:remote).with(no_args).and_return("git@github.com:#{owner}/#{repository_name}")

      expected_pr_number = 3
      expected_output = <<~STR
        Finding PR with head (#{owner}:#{branch})...
      STR

      actual_output = StringIO.new
      service_instance = described_class.new(repository, out: actual_output, git_client: git_client)

      service_result = VCR.use_cassette('github_com/comment_pr') do
        service_instance.execute(comment)
      end

      actual_pr_number = service_result.number

      expect(actual_output.string).to eql(expected_output)
      expect(actual_pr_number).to eql(expected_pr_number)
    end
  end # context 'with github.com'
end
