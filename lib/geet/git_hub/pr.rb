# frozen_string_literal: true

require_relative 'abstract_issue'

module Geet
  module GitHub
    class PR < AbstractIssue
      def self.create(repository, title, description, head, api_helper)
        request_address = "#{api_helper.repo_link}/pulls"
        request_data = { title: title, body: description, head: head, base: 'master' }

        response = api_helper.send_request(request_address, data: request_data)

        issue_number = response.fetch('number')

        new(repository, issue_number, api_helper)
      end

      def link
        "https://github.com/#{@repository.owner}/#{@repository.repo}/pull/#{@issue_number}"
      end

      def request_reviews(reviewers)
        request_data = { reviewers: reviewers }
        request_address = "#{@api_helper.repo_link}/pulls/#{@issue_number}/requested_reviewers"

        @api_helper.send_request(request_address, data: request_data)
      end
    end
  end
end
