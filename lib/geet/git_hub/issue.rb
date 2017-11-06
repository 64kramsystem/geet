# frozen_string_literal: true

require_relative 'abstract_issue'

module Geet
  module GitHub
    class Issue < AbstractIssue
      def self.create(title, description, api_helper)
        request_address = "#{api_helper.api_repo_link}/issues"
        request_data = { title: title, body: description, base: 'master' }

        response = api_helper.send_request(request_address, data: request_data)

        issue_number, title, link = response.fetch_values('number', 'title', 'html_url')

        new(issue_number, api_helper, title, link)
      end

      # See https://developer.github.com/v3/issues/#list-issues-for-a-repository
      #
      def self.list(api_helper)
        request_address = "#{api_helper.api_repo_link}/issues"

        response = api_helper.send_request(request_address, multipage: true)

        response.each_with_object([]) do |issue_data, result|
          if !issue_data.key?('pull_request')
            number = issue_data.fetch('number')
            title = issue_data.fetch('title')
            link = issue_data.fetch('html_url')

            result << new(number, api_helper, title, link)
          end
        end
      end
    end
  end
end
