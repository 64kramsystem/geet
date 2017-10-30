# frozen_string_literal: true

module Geet
  module GitHub
    # For clarity, in this class we keep only the identical logic between the subclasses, but
    # other methods could be moved in here at some complexity cost.
    class AbstractIssue
      attr_reader :issue_number

      # Returns an array of Struct(:number, :title); once this workflow is extended,
      # the struct will likely be converted to a standard class.
      #
      # See https://developer.github.com/v3/issues/#list-issues-for-a-repository
      #
      # options:
      #   filter: :pr, :issue, or nil
      #
      def self.list(api_helper, filter: nil)
        request_address = "#{api_helper.api_repo_link}/issues"

        response = api_helper.send_request(request_address, multipage: true)
        issue_class = Struct.new(:number, :title, :link)

        response.each_with_object([]) do |issue_data, result|
          include_issue = \
            filter.nil? ||
            filter == :pr && issue_data.key?('pull_request') ||
            filter == :issue && ! issue_data.key?('pull_request')

          if include_issue
            number = issue_data.fetch('number')
            title = issue_data.fetch('title')
            link = issue_data.fetch('html_url')

            result << issue_class.new(number, title, link)
          end
        end
      end

      def initialize(issue_number, api_helper)
        @issue_number = issue_number
        @api_helper = api_helper
      end

      # params:
      #   users:   String, or Array of strings.
      #
      def assign_user(users)
        request_data = { assignees: Array(users) }
        request_address = "#{@api_helper.api_repo_link}/issues/#{@issue_number}/assignees"

        @api_helper.send_request(request_address, data: request_data)
      end

      def add_labels(labels)
        request_data = labels
        request_address = "#{@api_helper.api_repo_link}/issues/#{@issue_number}/labels"

        @api_helper.send_request(request_address, data: request_data)
      end
    end
  end
end
