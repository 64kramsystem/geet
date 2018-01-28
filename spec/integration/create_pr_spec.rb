# frozen_string_literal: true

require 'spec_helper'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/create_pr'

describe Geet::Services::CreatePr do
  let(:git_client) { Geet::Utils::GitClient.new }
  let(:repository) { Geet::Git::Repository.new(git_client: git_client, warnings: false) }
  let(:upstream_repository) { Geet::Git::Repository.new(upstream: true, git_client: git_client, warnings: false) }

  context 'with labels, reviewers and milestones' do
    it 'should create a PR' do
      allow(git_client).to receive(:current_branch).and_return('mybranch1')
      allow(git_client).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo')

      expected_output = <<~STR
        Finding labels...
        Finding milestones...
        Finding collaborators...
        Creating PR...
        Assigning authenticated user...
        Adding labels bug, invalid...
        Setting milestone milestone 1...
        Requesting review from donald-fr...
        PR address: https://github.com/donaldduck/testrepo/pull/39
      STR

      actual_output = StringIO.new

      actual_created_pr = VCR.use_cassette('create_pr') do
        service_instance = described_class.new(repository, out: actual_output, git_client: git_client)
        service_instance.execute(
          'Title', 'Description',
          labels: 'bug,invalid', milestone: 'milestone 1', reviewers: 'donald-fr',
          no_open_pr: true, output: actual_output
        )
      end

      expect(actual_output.string).to eql(expected_output)

      expect(actual_created_pr.number).to eql(39)
      expect(actual_created_pr.title).to eql('Title')
      expect(actual_created_pr.link).to eql('https://github.com/donaldduck/testrepo/pull/39')
    end
  end

  it 'should create an upstream PR' do
    allow(git_client).to receive(:current_branch).and_return('mybranch')
    allow(git_client).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo_2f')
    allow(git_client).to receive(:remote).with('upstream').and_return('git@github.com:donald-fr/testrepo_u')

    expected_output = <<~STR
      Creating PR...
      Assigning authenticated user...
      PR address: https://github.com/donald-fr/testrepo_u/pull/4
    STR

    actual_output = StringIO.new

    actual_created_pr = VCR.use_cassette('create_pr_upstream') do
      service_instance = described_class.new(upstream_repository, out: actual_output, git_client: git_client)
      service_instance.execute('Title', 'Description', no_open_pr: true, output: actual_output)
    end

    expect(actual_output.string).to eql(expected_output)

    expect(actual_created_pr.number).to eql(4)
    expect(actual_created_pr.title).to eql('Title')
    expect(actual_created_pr.link).to eql('https://github.com/donald-fr/testrepo_u/pull/4')
  end

  context 'in automated mode' do
    it 'should raise an error when the working tree is dirty' do
      allow(git_client).to receive(:working_tree_clean?).and_return(false)
      allow(git_client).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo_2f')

      expected_output = <<~STR
        Error! Saved summary to /tmp/last_geet_edited_summary.md
      STR

      actual_output = StringIO.new

      operation = -> do
        service_instance = described_class.new(repository, out: actual_output, git_client: git_client)
        service_instance.execute('Title', 'Description', output: actual_output, automated_mode: true, no_open_pr: true)
      end

      expect(operation).to raise_error(RuntimeError, 'The working tree is not clean!')

      expect(actual_output.string).to eql(expected_output)
    end

    it 'should push to the upstream branch' do
      allow(git_client).to receive(:working_tree_clean?).and_return(true)
      allow(git_client).to receive(:current_branch).and_return('mybranch')
      expect(git_client).to receive(:upstream_branch).and_return('mybranch')
      expect(git_client).to receive(:push)

      allow(git_client).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo')

      expected_output = <<~STR
        Pushing to upstream branch...
        Creating PR...
        Assigning authenticated user...
        PR address: https://github.com/donaldduck/testrepo/pull/29
      STR

      actual_output = StringIO.new

      actual_created_pr = VCR.use_cassette('create_pr_in_auto_mode_with_push') do
        service_instance = described_class.new(repository, out: actual_output, git_client: git_client)
        service_instance.execute('Title', 'Description', output: actual_output, automated_mode: true, no_open_pr: true)
      end

      expect(actual_output.string).to eql(expected_output)
    end

    it "should create an upstream branch, when there isn't one" do
      allow(git_client).to receive(:working_tree_clean?).and_return(true)
      allow(git_client).to receive(:current_branch).and_return('mybranch')
      expect(git_client).to receive(:upstream_branch).and_return(nil)
      expect(git_client).to receive(:push).with(upstream_branch: 'mybranch')

      allow(git_client).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo')

      expected_output = <<~STR
        Creating upstream branch "mybranch"...
        Creating PR...
        Assigning authenticated user...
        PR address: https://github.com/donaldduck/testrepo/pull/30
      STR

      actual_output = StringIO.new

      actual_created_pr = VCR.use_cassette('create_pr_in_auto_mode_create_upstream') do
        service_instance = described_class.new(repository, out: actual_output, git_client: git_client)
        service_instance.execute('Title', 'Description', output: actual_output, automated_mode: true, no_open_pr: true)
      end

      expect(actual_output.string).to eql(expected_output)
    end
  end
end
