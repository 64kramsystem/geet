# frozen_string_literal: true

module Geet
  module GitHub
    # For clarity, in this class we keep only the identical logic between the subclasses, but
    # other methods could be moved in here at some complexity cost.
    class AbstractIssue
      attr_reader :issue_number

      def initialize(repository, issue_number, api_helper)
        @repository = repository
        @issue_number = issue_number
        @api_helper = api_helper
      end

      # params:
      #   users:   String, or Array of strings.
      #
      def assign_user(users)
        request_data = { assignees: Array(users) }
        request_address = "#{@api_helper.repo_link}/issues/#{@issue_number}/assignees"

        @api_helper.send_request(request_address, data: request_data)
      end

      def add_labels(labels)
        request_data = labels
        request_address = "#{@api_helper.repo_link}/issues/#{@issue_number}/labels"

        @api_helper.send_request(request_address, data: request_data)
      end
    end
  end
end
