# typed: strict
# frozen_string_literal: true

require "English"
require "open3"
require "shellwords"

module Geet
  module Helpers
    # Helper for services common workflow, for example, find the merge head.
    #
    module ServicesWorkflowHelper
      include Kernel
      extend T::Sig

      sig { void }
      def initialize
        @repository = T.let(T.unsafe(nil), Git::Repository)
        @git_client = T.let(T.unsafe(nil), Utils::GitClient)
        @out = T.let(T.unsafe(nil), IO)
      end

      # Expect to find only one.
      #
      # Requires: @out, @repository.
      #
      sig { returns(T.any(Geet::Github::PR, Geet::Gitlab::PR)) }
      def checked_find_branch_pr
        owner = if @repository.upstream?
          @repository.authenticated_user.username
        else
          @git_client.owner
        end

        head = @git_client.current_branch

        @out.puts "Finding PR with head (#{owner}:#{head})..."

        prs = @repository.prs(owner:, head:)

        raise "Expected to find only one PR for the current branch; found: #{prs.size}" if prs.size != 1

        T.must(prs[0])
      end
    end
  end
end
