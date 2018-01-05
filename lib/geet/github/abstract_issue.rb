# frozen_string_literal: true

module Geet
  module Github
    # It seems that autoloading will be deprecated, but it's currently the cleanest solution
    # to the legitimate problem of AbstractIssue needing Issue/PR to be loaded (due to :list),
    # and viceversa (due to class definition).
    autoload :Issue, File.expand_path('issue', __dir__)
    autoload :PR, File.expand_path('pr', __dir__)

    # For clarity, in this class we keep only the identical logic between the subclasses, but
    # other methods could be moved in here at some complexity cost.
    class AbstractIssue
      attr_reader :number, :title, :link

      def initialize(number, api_interface, title, link)
        @number = number
        @api_interface = api_interface
        @title = title
        @link = link
      end

      # See https://developer.github.com/v3/issues/#list-issues-for-a-repository
      #
      def self.list(api_interface, only_issues: false, milestone: nil, assignee: nil)
        api_path = 'issues'

        request_params = {}
        request_params[:milestone] = milestone if milestone
        request_params[:assignee] = assignee if assignee

        response = api_interface.send_request(api_path, params: request_params, multipage: true)

        abstract_issues_list = response.map do |issue_data|
          number = issue_data.fetch('number')
          title = issue_data.fetch('title')
          link = issue_data.fetch('html_url')

          klazz = issue_data.key?('pull_request') ? PR : Issue

          if !only_issues || klazz == Issue
            klazz.new(number, api_interface, title, link)
          end
        end

        abstract_issues_list.compact
      end

      # params:
      #   users:   String, or Array of strings.
      #
      def assign_users(users)
        api_path = "issues/#{@number}/assignees"
        request_data = { assignees: Array(users) }

        @api_interface.send_request(api_path, data: request_data)
      end

      # labels: array of strings.
      #
      def add_labels(labels)
        api_path = "issues/#{@number}/labels"
        request_data = labels

        @api_interface.send_request(api_path, data: request_data)
      end

      # See https://developer.github.com/v3/issues/#edit-an-issue
      #
      def edit(milestone:)
        request_data = { milestone: milestone }
        api_path = "issues/#{@number}"

        @api_interface.send_request(api_path, data: request_data, http_method: :patch)
      end
    end
  end
end
