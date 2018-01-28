# frozen_string_literal: true

module Geet
  module Services
    class MergePr
      DEFAULT_GIT_CLIENT = Geet::Utils::GitClient.new

      def initialize(repository, out: $stdout, git_client: DEFAULT_GIT_CLIENT)
        @repository = repository
        @out = out
        @git_client = git_client
      end

      def execute(delete_branch: false)
        merge_head = find_merge_head
        pr = checked_find_branch_pr(merge_head)
        merge_pr(pr)
        do_delete_branch if delete_branch
        pr
      end

      private

      def find_merge_head
        @git_client.current_branch
      end

      # Expect to find only one.
      def checked_find_branch_pr(head)
        @out.puts "Finding PR with head (#{head})..."

        prs = @repository.prs(head: head)

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
