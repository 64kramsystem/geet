# frozen_string_literal: true
# typed: strict

module Geet
  module Services
    # Merges the PR for the current branch.
    #
    # The workflow of this services is oriented to the a commondline usage: the user doesn't need
    # to lookup the merge for the working branch; this comes at the cost of extra operations and
    # constraints, but speeds up the workflow.
    #
    class MergePr
      extend T::Sig

      include Geet::Helpers::ServicesWorkflowHelper
      include Geet::Shared

      DEFAULT_GIT_CLIENT = Geet::Utils::GitClient.new

      sig { params(repository: Git::Repository, out: T.any(IO, StringIO), git_client: Utils::GitClient).void }
      def initialize(repository, out: $stdout, git_client: DEFAULT_GIT_CLIENT)
        @repository = repository
        @out = out
        @git_client = git_client
      end

      sig {
        params(
          delete_branch: T::Boolean,
          squash: T::Boolean
        )
        .returns(Github::PR)
      }
      def execute(delete_branch: false, squash: false)
        merge_method = "squash" if squash

        @git_client.fetch

        @git_client.push

        check_no_missing_upstream_commits if !squash

        pr = checked_find_branch_pr

        merge_pr(pr, merge_method:)

        if delete_branch
          branch = @git_client.current_branch

          delete_remote_branch(branch)
        end

        fetch_repository

        if @git_client.remote_branch_gone?
          pr_branch = @git_client.current_branch
          main_branch = @git_client.main_branch

          # The rebase could also be placed after the branch deletion. There are pros/cons;
          # currently, it's not important.
          #
          checkout_branch(main_branch)
          rebase

          # When squashing, we need to force delete, since Git doesn't recognize that the branch has
          # been merged.
          #
          delete_local_branch(pr_branch, force: squash)
        end

        pr
      end

      private

      sig { void }
      def check_no_missing_upstream_commits
        remote_main_branch = "#{Utils::GitClient::ORIGIN_NAME}/#{@git_client.main_branch}"
        missing_upstream_commits = @git_client.cherry("HEAD", head: remote_main_branch)

        raise "Found #{missing_upstream_commits.size} missing upstream commits!" if missing_upstream_commits.any?
      end

      sig { params(pr: Github::PR, merge_method: T.nilable(String)).void }
      def merge_pr(pr, merge_method: nil)
        @out.puts "Merging PR ##{pr.number}..."

        pr.merge(merge_method:)
      end

      sig { params(branch: String).void }
      def delete_remote_branch(branch)
        @out.puts "Deleting remote branch #{branch}..."

        @repository.delete_branch(branch)
      end

      sig { void }
      def fetch_repository
        @out.puts "Fetching repository..."

        @git_client.fetch
      end

      sig { params(branch: String).void }
      def checkout_branch(branch)
        @out.puts "Checking out #{branch}..."

        @git_client.checkout(branch)
      end

      sig { void }
      def rebase
        @out.puts "Rebasing..."

        @git_client.rebase
      end

      sig { params(branch: String, force: T::Boolean).void }
      def delete_local_branch(branch, force:)
        @out.puts "Deleting local branch #{branch}..."

        @git_client.delete_branch(branch, force:)
      end
    end
  end
end
