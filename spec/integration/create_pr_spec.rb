# frozen_string_literal: true

require 'spec_helper'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/create_pr'

describe Geet::Services::CreatePr do
  let(:git_client) { Geet::Utils::GitClient.new }
  let(:repository) { Geet::Git::Repository.new(git_client:, warnings: false) }
  let(:upstream_repository) { Geet::Git::Repository.new(upstream: true, git_client:, warnings: false) }

  context 'with github.com' do
    context 'with labels, reviewers and milestones' do
      it 'should create a PR' do
        allow(git_client).to receive(:working_tree_clean?).and_return(true)
        allow(git_client).to receive(:current_branch).and_return('mybranch')
        allow(git_client).to receive(:main_branch).and_return('master')
        allow(git_client).to receive(:remote).with(no_args).and_return('git@github.com:donaldduck/testrepo_f')
        allow(git_client).to receive(:remote_branch).and_return('mybranch')
        expect(git_client).to receive(:fetch)
        allow(git_client).to receive(:remote_branch_diff_commits).and_return([])
        expect(git_client).to receive(:push)

        expected_output = <<~STR
          Finding labels...
          Finding milestones...
          Finding collaborators...
          Pushing to remote branch...
          Creating PR...
          Adding labels bug, invalid...
          Setting milestone 0.0.1...
          Requesting review from donald-fr...
          PR address: https://github.com/donaldduck/testrepo_f/pull/1
        STR

        actual_output = StringIO.new

        actual_created_pr = VCR.use_cassette('github_com/create_pr', allow_unused_http_interactions: true) do
          service_instance = described_class.new(repository, out: actual_output, git_client:)
          service_instance.execute(
            'Title', 'Description',
            labels: 'bug,invalid', milestone: '0.0.1', reviewers: 'donald-fr'
          )
        end

        expect(actual_output.string).to eql(expected_output)

        expect(actual_created_pr.number).to eql(1)
        expect(actual_created_pr.title).to eql('Title')
        expect(actual_created_pr.link).to eql('https://github.com/donaldduck/testrepo_f/pull/1')
      end
    end

    context 'on an upstream repository' do
      it 'should create an upstream PR' do
        allow(git_client).to receive(:working_tree_clean?).and_return(true)
        allow(git_client).to receive(:current_branch).and_return('mybranch')
        allow(git_client).to receive(:main_branch).and_return('master')
        allow(git_client).to receive(:remote).with(no_args).and_return('git@github.com:donaldduck/testrepo_f')
        allow(git_client).to receive(:remote).with(name: 'upstream').and_return('git@github.com:donald-fr/testrepo_u')
        allow(git_client).to receive(:remote_defined?).with('upstream').and_return(true)
        allow(git_client).to receive(:remote_branch).and_return('mybranch')
        expect(git_client).to receive(:fetch)
        allow(git_client).to receive(:remote_branch_diff_commits).and_return([])
        expect(git_client).to receive(:push)

        expected_output = <<~STR
          Pushing to remote branch...
          Creating PR...
          PR address: https://github.com/donald-fr/testrepo_u/pull/8
        STR

        actual_output = StringIO.new

        actual_created_pr = VCR.use_cassette('github_com/create_pr_upstream', allow_unused_http_interactions: true) do
          service_instance = described_class.new(upstream_repository, out: actual_output, git_client:)
          service_instance.execute('Title', 'Description')
        end

        expect(actual_output.string).to eql(expected_output)

        expect(actual_created_pr.number).to eql(8)
        expect(actual_created_pr.title).to eql('Title')
        expect(actual_created_pr.link).to eql('https://github.com/donald-fr/testrepo_u/pull/8')
      end

      # It would be more consistent to have this UT outside of an upstream context, however this use
      # case is actually a typical real-world one
      #
      context 'without write permissions' do
        context 'without labels, reviewers and milestones' do
          it 'should create a PR' do
            allow(git_client).to receive(:working_tree_clean?).and_return(true)
            allow(git_client).to receive(:current_branch).and_return('mybranch')
            allow(git_client).to receive(:main_branch).and_return('master')
            allow(git_client).to receive(:remote).with(no_args).and_return('git@github.com:donaldduck/testrepo_f')
            allow(git_client).to receive(:remote).with(name: 'upstream').and_return('git@github.com:donald-fr/testrepo_u')
            allow(git_client).to receive(:remote_defined?).with('upstream').and_return(true)
            allow(git_client).to receive(:remote_branch).and_return('mybranch')
            expect(git_client).to receive(:fetch)
            allow(git_client).to receive(:remote_branch_diff_commits).and_return([])
            expect(git_client).to receive(:push)

            expected_output = <<~STR
              Pushing to remote branch...
              Creating PR...
              PR address: https://github.com/donald-fr/testrepo_u/pull/9
            STR

            actual_output = StringIO.new

            actual_created_pr = VCR.use_cassette('github_com/create_pr_upstream_without_write_permissions') do
              service_instance = described_class.new(upstream_repository, out: actual_output, git_client:)
              service_instance.execute(
                'Title', 'Description',
                labels: '<ignored>'
              )
            end

            expect(actual_output.string).to eql(expected_output)

            expect(actual_created_pr.number).to eql(9)
            expect(actual_created_pr.title).to eql('Title')
            expect(actual_created_pr.link).to eql('https://github.com/donald-fr/testrepo_u/pull/9')
          end
        end
      end
    end

    context 'in automated mode' do
      it 'should raise an error when the working tree is dirty' do
        allow(git_client).to receive(:working_tree_clean?).and_return(false)
        allow(git_client).to receive(:remote).with(no_args).and_return('git@github.com:donaldduck/testrepo_f')

        actual_output = StringIO.new

        expect do
          service_instance = described_class.new(repository, out: actual_output, git_client:)
          service_instance.execute('Title', 'Description')
        end.to raise_error(RuntimeError, 'The working tree is not clean!')

        expect(actual_output.string).to be_empty
      end

      it 'should push to the remote branch' do
        allow(git_client).to receive(:working_tree_clean?).and_return(true)
        allow(git_client).to receive(:current_branch).and_return('mybranch')
        allow(git_client).to receive(:main_branch).and_return('master')
        expect(git_client).to receive(:remote_branch).and_return('mybranch')
        expect(git_client).to receive(:fetch)
        allow(git_client).to receive(:remote_branch_diff_commits).and_return([])
        expect(git_client).to receive(:push)

        allow(git_client).to receive(:remote).with(no_args).and_return('git@github.com:donaldduck/testrepo_f')

        expected_output = <<~STR
          Pushing to remote branch...
          Creating PR...
          PR address: https://github.com/donaldduck/testrepo_f/pull/2
        STR

        actual_output = StringIO.new

        actual_created_pr = VCR.use_cassette('github_com/create_pr_in_auto_mode_with_push', allow_unused_http_interactions: true) do
          service_instance = described_class.new(repository, out: actual_output, git_client:)
          service_instance.execute('Title', 'Description')
        end

        expect(actual_output.string).to eql(expected_output)
      end

      it "should create a remote branch, when there isn't one (is not tracked)" do
        allow(git_client).to receive(:working_tree_clean?).and_return(true)
        allow(git_client).to receive(:current_branch).and_return('mybranch')
        allow(git_client).to receive(:main_branch).and_return('master')
        expect(git_client).to receive(:remote_branch).and_return(nil)
        expect(git_client).to receive(:push).with(remote_branch: 'mybranch')

        allow(git_client).to receive(:remote).with(no_args).and_return('git@github.com:donaldduck/testrepo_f')

        expected_output = <<~STR
          Creating remote branch "mybranch"...
          Creating PR...
          PR address: https://github.com/donaldduck/testrepo_f/pull/4
        STR

        actual_output = StringIO.new

        actual_created_pr = VCR.use_cassette('github_com/create_pr_in_auto_mode_create_upstream', allow_unused_http_interactions: true) do
          service_instance = described_class.new(repository, out: actual_output, git_client:)
          service_instance.execute('Title', 'Description')
        end

        expect(actual_output.string).to eql(expected_output)
      end

      it 'should enable automerge after creating a PR' do
        allow(git_client).to receive(:working_tree_clean?).and_return(true)
        allow(git_client).to receive(:current_branch).and_return('mybranch')
        allow(git_client).to receive(:main_branch).and_return('master')
        allow(git_client).to receive(:remote_branch).and_return('mybranch')
        allow(git_client).to receive(:remote_branch_diff_commits).and_return([])
        allow(git_client).to receive(:fetch)
        allow(git_client).to receive(:push)
        allow(git_client).to receive(:remote).with(no_args).and_return('git@github.com:donaldduck/testrepo_f')

        actual_output = StringIO.new

        # Mock the repository and PR
        allow(repository).to receive(:authenticated_user).and_return(
          double(is_collaborator?: true, has_permission?: true)
        )

        mock_pr = double(
          'PR',
          number: 1,
          title: 'Title',
          link: 'https://github.com/donaldduck/testrepo_f/pull/1',
          node_id: 'PR_test123'
        )
        allow(mock_pr).to receive(:enable_automerge)

        allow(repository).to receive(:create_pr).and_return(mock_pr)

        service_instance = described_class.new(repository, out: actual_output, git_client:)
        service_instance.execute('Title', 'Description', automerge: true)

        expect(mock_pr).to have_received(:enable_automerge)
        expect(actual_output.string).to include('Enabling automerge...')
      end

      it 'should raise an error when automerge is requested but not supported' do
        allow(git_client).to receive(:working_tree_clean?).and_return(true)
        allow(git_client).to receive(:current_branch).and_return('mybranch')
        allow(git_client).to receive(:main_branch).and_return('master')
        allow(git_client).to receive(:remote_branch).and_return('mybranch')
        allow(git_client).to receive(:remote_branch_diff_commits).and_return([])
        allow(git_client).to receive(:fetch)
        allow(git_client).to receive(:push)
        allow(git_client).to receive(:remote).with(no_args).and_return('git@github.com:donaldduck/testrepo_f')

        actual_output = StringIO.new

        # Mock the repository and PR without enable_automerge method (simulating GitLab)
        allow(repository).to receive(:authenticated_user).and_return(
          double(is_collaborator?: true, has_permission?: true)
        )

        mock_pr = double(
          'PR',
          number: 1,
          title: 'Title',
          link: 'https://github.com/donaldduck/testrepo_f/pull/1'
        )

        allow(repository).to receive(:create_pr).and_return(mock_pr)

        service_instance = described_class.new(repository, out: actual_output, git_client:)

        expect do
          service_instance.execute('Title', 'Description', automerge: true)
        end.to raise_error(RuntimeError, 'Automerge is not supported for this repository provider')
      end
    end
  end # context 'with github.com'
end
