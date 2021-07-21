# frozen_string_literal: true

require 'English'
require 'open3'
require 'shellwords'

module Geet
  module Helpers
    # Helper for services common workflow, for example, find the merge head.
    #
    module ServicesWorkflowHelper
      # Expect to find only one.
      #
      # Requires: @out, @repository.
      #
      def checked_find_branch_pr
        owner = @git_client.owner
        head = @git_client.current_branch

        @out.puts "Finding PR with head (#{owner}:#{head})..."

        prs = @repository.prs(owner: owner, head: head)

        raise "Expected to find only one PR for the current branch; found: #{prs.size}" if prs.size != 1

        prs[0]
      end
    end
  end
end
