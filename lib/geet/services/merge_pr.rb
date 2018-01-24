# frozen_string_literal: true

module Geet
  module Services
    class MergePr
      DEFAULT_GIT_CLIENT = Geet::Utils::GitClient.new

      def initialize(repository, git_client: DEFAULT_GIT_CLIENT)
        @repository = repository
        @git_client = git_client
      end

      def execute(delete_branch: false, output: $stdout)
        merge_head = find_merge_head
        pr = checked_find_branch_pr(merge_head, output)
        merge_pr(pr, output)
        do_delete_branch(output) if delete_branch
        pr
      end

      private

      def find_merge_head
        @git_client.current_branch
      end

      # Expect to find only one.
      def checked_find_branch_pr(head, output)
        output.puts "Finding PR with head (#{head})..."

        prs = @repository.prs(head: head)

        raise "Expected to find only one PR for the current branch; found: #{prs.size}" if prs.size != 1

        prs[0]
      end

      def merge_pr(pr, output)
        output.puts "Merging PR ##{pr.number}..."

        pr.merge
      end

      def do_delete_branch(output)
        output.puts "Deleting branch #{@git_client.current_branch}..."

        @repository.delete_branch(@git_client.current_branch)
      end
    end
  end
end
