# frozen_string_literal: true

module Geet
  module Github
    # See AbstractIssue for the circular dependency issue notes.
    autoload :AbstractIssue, File.expand_path('abstract_issue', __dir__)

    class PR < AbstractIssue
      # See https://developer.github.com/v3/pulls/#create-a-pull-request
      #
      def self.create(title, description, head, api_interface)
        api_path = 'pulls'

        if api_interface.upstream?
          authenticated_user = Geet::Github::User.authenticated(api_interface).username
          head = "#{authenticated_user}:#{head}"
        end

        request_data = { title: title, body: description, head: head, base: 'master' }

        response = api_interface.send_request(api_path, data: request_data)

        number, title, link = response.fetch_values('number', 'title', 'html_url')

        new(number, api_interface, title, link)
      end

      # See https://developer.github.com/v3/pulls/#list-pull-requests
      #
      def self.list(api_interface, head: nil)
        api_path = 'pulls'
        request_params = { head: head } if head

        response = api_interface.send_request(api_path, params: request_params, multipage: true)

        response.map do |issue_data|
          number = issue_data.fetch('number')
          title = issue_data.fetch('title')
          link = issue_data.fetch('html_url')

          new(number, api_interface, title, link)
        end
      end

      # See https://developer.github.com/v3/pulls/#merge-a-pull-request-merge-button
      #
      def merge
        api_path = "pulls/#{number}/merge"

        @api_interface.send_request(api_path, http_method: :put)
      end

      def request_review(reviewers)
        api_path = "pulls/#{number}/requested_reviewers"
        request_data = { reviewers: reviewers }

        @api_interface.send_request(api_path, data: request_data)
      end
    end
  end
end
