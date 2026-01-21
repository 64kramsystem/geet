# frozen_string_literal: true
# typed: strict

require "stringio"

module Geet
  module Services
    # Open in the browser the PR for the current branch.
    #
    class OpenPr
      extend T::Sig

      include Geet::Helpers::OsHelper
      include Geet::Helpers::ServicesWorkflowHelper

      DEFAULT_GIT_CLIENT = Geet::Utils::GitClient.new

      sig {
        params(
          repository: Git::Repository,
          out: IO,
          git_client: Utils::GitClient
        ).void
      }
      def initialize(repository, out: $stdout, git_client: DEFAULT_GIT_CLIENT)
        @repository = repository
        @out = out
        @git_client = git_client
      end

      sig {
        params(
          delete_branch: T::Boolean
        ).returns(T.any(Github::PR, Gitlab::PR))
      }
      def execute(delete_branch: false)
        pr = checked_find_branch_pr
        open_file_with_default_application(pr.link)
        pr
      end
    end
  end
end
