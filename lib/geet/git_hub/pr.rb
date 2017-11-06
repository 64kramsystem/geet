# frozen_string_literal: true

require_relative 'abstract_issue'

module Geet
  module GitHub
    class PR < AbstractIssue
      def self.create(repository, title, description, head, api_helper)
        request_address = "#{api_helper.api_repo_link}/pulls"

        head = "#{repository.authenticated_user}:#{head}" if api_helper.upstream?
        request_data = { title: title, body: description, head: head, base: 'master' }

        response = api_helper.send_request(request_address, data: request_data)

        issue_number = response.fetch('number')

        new(issue_number, api_helper)
      end

      # Returns an array of Struct(:number, :title); once this workflow is extended,
      # the struct will likely be converted to a standard class.
      #
      # See https://developer.github.com/v3/pulls/#list-pull-requests
      #
      def self.list(api_helper)
        request_address = "#{api_helper.api_repo_link}/pulls"

        response = api_helper.send_request(request_address, multipage: true)
        issue_class = Struct.new(:number, :title, :link)

        response.map do |issue_data|
          number = issue_data.fetch('number')
          title = issue_data.fetch('title')
          link = issue_data.fetch('html_url')

          issue_class.new(number, title, link)
        end
      end

      def link
        "#{@api_helper.repo_link}/pull/#{@issue_number}"
      end

      def request_review(reviewers)
        request_data = { reviewers: reviewers }
        request_address = "#{@api_helper.api_repo_link}/pulls/#{@issue_number}/requested_reviewers"

        @api_helper.send_request(request_address, data: request_data)
      end
    end
  end
end
