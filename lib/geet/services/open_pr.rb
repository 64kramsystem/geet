# frozen_string_literal: true

require_relative '../helpers/os_helper'
require_relative '../helpers/services_workflow_helper'

module Geet
  module Services
    # Open in the browser the PR for the current branch.
    #
    class OpenPr
      include Geet::Helpers::OsHelper
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
        open_file_with_default_application(pr.link)
        pr
      end
    end
  end
end
