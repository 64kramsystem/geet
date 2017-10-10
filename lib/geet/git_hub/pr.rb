# frozen_string_literal: true

module Geet
  module GitHub
    class PR
      attr_reader :issue_number, :link

      def self.create(title, description, head, api_helper)
        request_address = "#{api_helper.repo_link}/pulls"
        request_data = { title: title, body: description, head: head, base: 'master' }

        response = api_helper.send_request(request_address, data: request_data)

        issue_number = response.fetch('number')
        issue_link = response['_links']['html']['href']

        new(issue_number, issue_link, api_helper)
      end

      def initialize(issue_number, link, api_helper)
        @issue_number = issue_number
        @link = link
        @api_helper = api_helper
      end

      def assign_user(user)
        request_data = { assignees: [user] }
        request_address = "#{@api_helper.repo_link}/issues/#{@issue_number}/assignees"

        @api_helper.send_request(request_address, data: request_data)
      end

      def add_labels(labels)
        request_data = labels
        request_address = "#{@api_helper.repo_link}/issues/#{@issue_number}/labels"

        @api_helper.send_request(request_address, data: request_data)
      end

      def request_reviews(reviewers)
        request_data = { reviewers: reviewers }
        request_address = "#{@api_helper.repo_link}/pulls/#{@issue_number}/requested_reviewers"

        @api_helper.send_request(request_address, data: request_data)
      end
    end
  end
end
