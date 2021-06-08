# frozen_string_literal: true

module Geet
  module Github
    # See AbstractIssue for the circular dependency issue notes.
    autoload :AbstractIssue, File.expand_path('abstract_issue', __dir__)

    class Issue < Geet::Github::AbstractIssue
      def self.create(title, description, api_interface, **)
        api_path = 'issues'
        request_data = { title: title, body: description }

        response = api_interface.send_request(api_path, data: request_data)

        issue_number, title, link = response.fetch_values('number', 'title', 'html_url')

        new(issue_number, api_interface, title, link)
      end

      def self.list(api_interface, assignee: nil, milestone: nil)
        super do |issue_data|
          !issue_data.key?('pull_request')
        end
      end
    end
  end
end
