# frozen_string_literal: true

require 'spec_helper'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/create_pr'

describe Geet::Services::CreatePr do
  let(:git_client) { Geet::Utils::GitClient.new }
  let(:repository) { Geet::Git::Repository.new(git_client: git_client, warnings: false) }
  let(:upstream_repository) { Geet::Git::Repository.new(upstream: true, git_client: git_client, warnings: false) }

  context 'with github.com' do
    context 'with labels, reviewers and milestones' do
      it 'should create a PR' do
        allow(git_client).to receive(:current_branch).and_return('mybranch')
        allow(git_client).to receive(:main_branch).and_return('master')
        allow(git_client).to receive(:remote).with(no_args).and_return('git@github.com:donaldduck/testrepo_f')

        expected_output = <<~STR
          Finding labels...
          Finding milestones...
          Finding collaborators...
          Creating PR...
          Assigning authenticated user...
          Adding labels bug, invalid...
          Setting milestone 0.0.1...
          Requesting review from donald-fr...
          PR address: https://github.com/donaldduck/testrepo_f/pull/1
        STR

        actual_output = StringIO.new

        actual_created_pr = VCR.use_cassette('github_com/create_pr') do
          service_instance = described_class.new(repository, out: actual_output, git_client: git_client)
          service_instance.execute(
            'Title', 'Description',
            labels: 'bug,invalid', milestone: '0.0.1', reviewers: 'donald-fr',
            no_open_pr: true, output: actual_output
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
        allow(git_client).to receive(:current_branch).and_return('mybranch')
        allow(git_client).to receive(:main_branch).and_return('master')
        allow(git_client).to receive(:remote).with(no_args).and_return('git@github.com:donaldduck/testrepo_f')
        allow(git_client).to receive(:remote).with(name: 'upstream').and_return('git@github.com:donald-fr/testrepo_u')

        expected_output = <<~STR
          Creating PR...
          Assigning authenticated user...
          PR address: https://github.com/donald-fr/testrepo_u/pull/8
        STR

        actual_output = StringIO.new

        actual_created_pr = VCR.use_cassette('github_com/create_pr_upstream') do
          service_instance = described_class.new(upstream_repository, out: actual_output, git_client: git_client)
          service_instance.execute('Title', 'Description', no_open_pr: true, output: actual_output)
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
            allow(git_client).to receive(:current_branch).and_return('mybranch')
            allow(git_client).to receive(:main_branch).and_return('master')
            allow(git_client).to receive(:remote).with(no_args).and_return('git@github.com:donaldduck/testrepo_f')
            allow(git_client).to receive(:remote).with(name: 'upstream').and_return('git@github.com:donald-fr/testrepo_u')

            expected_output = <<~STR
              Creating PR...
              PR address: https://github.com/donald-fr/testrepo_u/pull/9
            STR

            actual_output = StringIO.new

            actual_created_pr = VCR.use_cassette('github_com/create_pr_upstream_without_write_permissions') do
              service_instance = described_class.new(upstream_repository, out: actual_output, git_client: git_client)
              service_instance.execute(
                'Title', 'Description',
                labels: '<ignored>',
                no_open_pr: true, output: actual_output
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
        allow(git_client).to receive(:main_branch).and_return('master')
        expect(git_client).to receive(:remote_branch).and_return('mybranch')
        expect(git_client).to receive(:push)

        allow(git_client).to receive(:remote).with(no_args).and_return('git@github.com:donaldduck/testrepo_f')

        expected_output = <<~STR
          Pushing to upstream branch...
          Creating PR...
          Assigning authenticated user...
          PR address: https://github.com/donaldduck/testrepo_f/pull/2
        STR

        actual_output = StringIO.new

        actual_created_pr = VCR.use_cassette('github_com/create_pr_in_auto_mode_with_push') do
          service_instance = described_class.new(repository, out: actual_output, git_client: git_client)
          service_instance.execute('Title', 'Description', output: actual_output, automated_mode: true, no_open_pr: true)
        end

        expect(actual_output.string).to eql(expected_output)
      end

      it "should create an upstream branch, when there isn't one (is not tracked)" do
        allow(git_client).to receive(:working_tree_clean?).and_return(true)
        allow(git_client).to receive(:current_branch).and_return('mybranch')
        allow(git_client).to receive(:main_branch).and_return('master')
        expect(git_client).to receive(:remote_branch).and_return(nil)
        expect(git_client).to receive(:push).with(remote_branch: 'mybranch')

        allow(git_client).to receive(:remote).with(no_args).and_return('git@github.com:donaldduck/testrepo_f')

        expected_output = <<~STR
          Creating upstream branch "mybranch"...
          Creating PR...
          Assigning authenticated user...
          PR address: https://github.com/donaldduck/testrepo_f/pull/4
        STR

        actual_output = StringIO.new

        actual_created_pr = VCR.use_cassette('github_com/create_pr_in_auto_mode_create_upstream') do
          service_instance = described_class.new(repository, out: actual_output, git_client: git_client)
          service_instance.execute('Title', 'Description', output: actual_output, automated_mode: true, no_open_pr: true)
        end

        expect(actual_output.string).to eql(expected_output)
      end
    end
  end # context 'with github.com'
end
