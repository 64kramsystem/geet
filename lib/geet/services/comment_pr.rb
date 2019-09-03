# frozen_string_literal: true

require_relative '../helpers/os_helper'
require_relative '../helpers/services_workflow_helper'

module Geet
  module Services
    # Add a comment to the PR for the current branch.
    #
    class CommentPr
      include Geet::Helpers::OsHelper
      include Geet::Helpers::ServicesWorkflowHelper

      DEFAULT_GIT_CLIENT = Geet::Utils::GitClient.new

      def initialize(repository, out: $stdout, git_client: DEFAULT_GIT_CLIENT)
        @repository = repository
        @out = out
        @git_client = git_client
      end

      def execute(comment, no_open_pr: nil)
        merge_owner, merge_head = find_merge_head
        pr = checked_find_branch_pr(merge_owner, merge_head)
        pr.comment(comment)
        open_file_with_default_application(pr.link) unless no_open_pr
        pr
      end
    end
  end
end
