# frozen_string_literal: true

require 'spec_helper'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/create_issue'

describe Geet::Services::CreateIssue do
  let(:git_client) { Geet::Utils::GitClient.new }
  let(:repository) { Geet::Git::Repository.new(git_client: git_client) }
  let(:upstream_repository) { Geet::Git::Repository.new(upstream: true, git_client: git_client) }

  context 'with labels, assignees and milestones' do
    it 'should create an issue' do
      allow(git_client).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo')

      expected_output = <<~STR
        Finding labels...
        Finding milestone...
        Finding collaborators...
        Creating the issue...
        Adding labels bug, invalid...
        Setting milestone 0.0.1...
        Assigning users donald-ts, donald-fr...
        Issue address: https://github.com/donaldduck/testrepo/issues/1
      STR

      actual_output = StringIO.new

      actual_created_issue = VCR.use_cassette('create_issue') do
        described_class.new(repository).execute(
          'Title', 'Description',
          labels: 'bug,invalid', milestone_pattern: '0.0.1', assignee_patterns: 'donald-ts,donald-fr',
          no_open_issue: true, output: actual_output
        )
      end

      expect(actual_output.string).to eql(expected_output)

      expect(actual_created_issue.number).to eql(1)
      expect(actual_created_issue.title).to eql('Title')
      expect(actual_created_issue.link).to eql('https://github.com/donaldduck/testrepo/issues/1')
    end
  end

  it 'should create an upstream issue' do
    allow(git_client).to receive(:current_branch).and_return('mybranch')
    allow(git_client).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo')
    allow(git_client).to receive(:remote).with('upstream').and_return('git@github.com:donald-fr/testrepo_u')

    expected_output = <<~STR
      Creating the issue...
      Issue address: https://github.com/donald-fr/testrepo_u/issues/7
    STR

    actual_output = StringIO.new

    actual_created_issue = VCR.use_cassette('create_issue_upstream') do
      create_options = { no_open_issue: true, output: actual_output }
      described_class.new(upstream_repository).execute('Title', 'Description', create_options)
    end

    expect(actual_output.string).to eql(expected_output)

    expect(actual_created_issue.number).to eql(7)
    expect(actual_created_issue.title).to eql('Title')
    expect(actual_created_issue.link).to eql('https://github.com/donald-fr/testrepo_u/issues/7')
  end
end
