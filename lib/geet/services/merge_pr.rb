# frozen_string_literal: true

module Geet
  module Services
    # Merges the PR for the current branch.
    #
    # The workflow of this services is oriented to the a commondline usage: the user doesn't need
    # to lookup the merge for the working branch; this comes at the cost of extra operations and
    # constraints, but speeds up the workflow.
    #
    class MergePr
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

      def find_merge_head
        [@git_client.owner, @git_client.current_branch]
      end

      # Expect to find only one.
      def checked_find_branch_pr(owner, head)
        @out.puts "Finding PR with head (#{owner}:#{head})..."

        prs = @repository.prs(owner: owner, head: head)

        raise "Expected to find only one PR for the current branch; found: #{prs.size}" if prs.size != 1

        prs[0]
      end

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
