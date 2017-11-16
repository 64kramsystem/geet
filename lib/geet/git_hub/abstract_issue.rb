# frozen_string_literal: true

module Geet
  module GitHub
    # It seems that autoloading will be deprecated, but it's currently the cleanest solution
    # to the legitimate problem of AbstractIssue needing Issue/PR to be loaded (due to :list),
    # and viceversa (due to class definition).
    autoload :Issue, File.expand_path('issue', __dir__)
    autoload :PR, File.expand_path('pr', __dir__)

    # For clarity, in this class we keep only the identical logic between the subclasses, but
    # other methods could be moved in here at some complexity cost.
    class AbstractIssue
      attr_reader :number, :title, :link

      def initialize(number, api_helper, title, link)
        @number = number
        @api_helper = api_helper
        @title = title
        @link = link
      end

      # See https://developer.github.com/v3/issues/#list-issues-for-a-repository
      #
      def self.list(api_helper, milestone: nil)
        api_path = 'issues'
        request_params = { milestone: milestone } if milestone

        response = api_helper.send_request(api_path, params: request_params, multipage: true)

        response.map do |issue_data|
          number = issue_data.fetch('number')
          title = issue_data.fetch('title')
          link = issue_data.fetch('html_url')

          klazz = issue_data.key?('pull_request') ? PR : Issue

          klazz.new(number, api_helper, title, link)
        end
      end

      # params:
      #   users:   String, or Array of strings.
      #
      def assign_users(users)
        api_path = "issues/#{@number}/assignees"
        request_data = { assignees: Array(users) }

        @api_helper.send_request(api_path, data: request_data)
      end

      def add_labels(labels)
        api_path = "issues/#{@number}/labels"
        request_data = labels

        @api_helper.send_request(api_path, data: request_data)
      end

      # See https://developer.github.com/v3/issues/#edit-an-issue
      #
      def edit(milestone:)
        request_data = { milestone: milestone }
        api_path = "issues/#{@number}"

        @api_helper.send_request(api_path, data: request_data, http_method: :patch)
      end
    end
  end
end
