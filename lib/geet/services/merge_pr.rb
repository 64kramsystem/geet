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

      DEFAULT_GIT_CLIENT = Geet::Utils::GitClient.new

      def initialize(repository, out: $stdout, git_client: DEFAULT_GIT_CLIENT)
        @repository = repository
        @out = out
        @git_client = git_client
      end

      def execute(delete_branch: false)
        merge_owner, merge_head = find_merge_head
        pr = checked_find_branch_pr(merge_owner, merge_head)
        merge_pr(pr)
        do_delete_branch if delete_branch
        pr
      end

      private

      def merge_pr(pr)
        @out.puts "Merging PR ##{pr.number}..."

        pr.merge
      end

      def do_delete_branch
        @out.puts "Deleting branch #{@git_client.current_branch}..."

        @repository.delete_branch(@git_client.current_branch)
      end
    end
  end
end
