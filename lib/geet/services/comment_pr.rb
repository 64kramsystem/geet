# frozen_string_literal: true
# typed: strict

module Geet
  module Services
    # Add a comment to the PR for the current branch.
    #
    class CommentPr
      extend T::Sig

      include Geet::Helpers::OsHelper
      include Geet::Helpers::ServicesWorkflowHelper

      DEFAULT_GIT_CLIENT = Geet::Utils::GitClient.new

      sig { params(repository: Git::Repository, out: T.any(IO, StringIO), git_client: Utils::GitClient).void }
      def initialize(repository, out: $stdout, git_client: DEFAULT_GIT_CLIENT)
        @repository = repository
        @out = out
        @git_client = git_client
      end

      sig {
        params(
          comment: String,
          open_browser: T::Boolean
        )
        .returns(T.any(Github::PR, Gitlab::PR))
      }
      def execute(comment, open_browser: false)
        pr = checked_find_branch_pr
        pr.comment(comment)
        open_file_with_default_application(pr.link) if open_browser
        pr
      end
    end
  end
end
