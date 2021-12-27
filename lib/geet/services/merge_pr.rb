# frozen_string_literal: true

require_relative '../helpers/services_workflow_helper'

module Geet
  module Services
    # Merges the PR for the current branch.
    #
    # The workflow of this services is oriented to the a commondline usage: the user doesn't need
    # to lookup the merge for the working branch; this comes at the cost of extra operations and
    # constraints, but speeds up the workflow.
    #
    class MergePr
      include Geet::Helpers::ServicesWorkflowHelper
      include Geet::Shared

      DEFAULT_GIT_CLIENT = Geet::Utils::GitClient.new

      def initialize(repository, out: $stdout, git_client: DEFAULT_GIT_CLIENT)
        @repository = repository
        @out = out
        @git_client = git_client
      end

      def execute(delete_branch: false)
        pr = checked_find_branch_pr

        merge_pr(pr)

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

          delete_local_branch(pr_branch)
        end

        pr
      end

      private

      def merge_pr(pr)
        @out.puts "Merging PR ##{pr.number}..."

        pr.merge
      end

      def delete_remote_branch(branch)
        @out.puts "Deleting remote branch #{branch}..."

        @repository.delete_branch(branch)
      end

      def fetch_repository
        @out.puts "Fetching repository..."

        @git_client.fetch
      end

      def checkout_branch(branch)
        @out.puts "Checking out #{branch}..."

        @git_client.checkout(branch)
      end

      def rebase
        @out.puts "Rebasing..."

        @git_client.rebase
      end

      def delete_local_branch(branch)
        @out.puts "Deleting local branch #{branch}..."

        @git_client.delete_branch(branch)
      end
    end
  end
end
