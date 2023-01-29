# frozen_string_literal: true

require 'spec_helper'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/create_issue'

describe Geet::Services::CreateIssue do
  let(:git_client) { Geet::Utils::GitClient.new }
  let(:repository) { Geet::Git::Repository.new(warnings: false, git_client: git_client) }
  let(:upstream_repository) { Geet::Git::Repository.new(upstream: true, git_client: git_client) }

  context 'with labels, assignees and milestones' do
    it 'should create an issue' do
      allow(git_client).to receive(:remote).with(no_args).and_return('git@github.com:donaldduck/testrepo_f')

      expected_output = <<~STR
        Finding labels...
        Finding milestones...
        Finding collaborators...
        Creating the issue...
        Adding labels bug, invalid...
        Setting milestone 0.0.1...
        Assigning users donaldduck, donald-fr...
        Issue address: https://github.com/donaldduck/testrepo_f/issues/2
      STR

      actual_output = StringIO.new

      actual_created_issue = VCR.use_cassette('create_issue') do
        described_class.new(repository, out: actual_output).execute(
          'Title', 'Description',
          labels: 'bug,invalid', milestone: '0.0.1', assignees: 'donaldduck,donald-fr',
          open_browser: false
        )
      end

      expect(actual_output.string).to eql(expected_output)

      expect(actual_created_issue.number).to eql(2)
      expect(actual_created_issue.title).to eql('Title')
      expect(actual_created_issue.link).to eql('https://github.com/donaldduck/testrepo_f/issues/2')
    end
  end

  context 'without write permissions' do
    context 'without labels, assignees and milestones' do
      it 'should create an upstream issue' do
        allow(git_client).to receive(:current_branch).and_return('mybranch')
        allow(git_client).to receive(:remote).with(no_args).and_return('git@github.com:donaldduck/testrepo')
        allow(git_client).to receive(:remote).with(name: 'upstream').and_return('git@github.com:momcorp/therepo')

        expected_output = <<~STR
          Creating the issue...
          Issue address: https://github.com/momcorp/therepo/issues/42
        STR

        actual_output = StringIO.new

        actual_created_issue = VCR.use_cassette('create_issue_upstream') do
          create_options = { open_browser: false, out: actual_output }
          described_class.new(upstream_repository, out: actual_output).execute('Title', 'Description', **create_options)
        end

        expect(actual_output.string).to eql(expected_output)

        expect(actual_created_issue.number).to eql(42)
        expect(actual_created_issue.title).to eql('Title')
        expect(actual_created_issue.link).to eql('https://github.com/momcorp/therepo/issues/42')
      end
    end
  end
end
