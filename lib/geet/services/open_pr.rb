# frozen_string_literal: true

require_relative '../helpers/os_helper'

module Geet
  module Services
    # Open in the browser the PR for the current branch.
    #
    class OpenPr
      include Geet::Helpers::OsHelper

      DEFAULT_GIT_CLIENT = Geet::Utils::GitClient.new

      def initialize(repository, out: $stdout, git_client: DEFAULT_GIT_CLIENT)
        @repository = repository
        @out = out
        @git_client = git_client
      end

      def execute(delete_branch: false)
        merge_owner, merge_head = find_merge_head
        pr = checked_find_branch_pr(merge_owner, merge_head)
        open_file_with_default_application(pr.link)
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
    end
  end
end
