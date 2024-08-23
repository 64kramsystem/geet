# frozen_string_literal: true

module Geet
  module Github
    # See AbstractIssue for the circular dependency issue notes.
    autoload :AbstractIssue, File.expand_path('abstract_issue', __dir__)

    class PR < AbstractIssue
      # See https://developer.github.com/v3/pulls/#create-a-pull-request
      #
      def self.create(title, description, head, api_interface, base, draft: false)
        api_path = 'pulls'

        if api_interface.upstream?
          authenticated_user = Geet::Github::User.authenticated(api_interface).username
          head = "#{authenticated_user}:#{head}"
        end

        request_data = { title: title, body: description, head: head, base: base, draft: draft }

        response = api_interface.send_request(api_path, data: request_data)

        number, title, link = response.fetch_values('number', 'title', 'html_url')

        new(number, api_interface, title, link)
      end

      # See https://developer.github.com/v3/pulls/#list-pull-requests
      #
      def self.list(api_interface, milestone: nil, assignee: nil, owner: nil, head: nil)
        check_list_params!(milestone, assignee, head)

        if head
          api_path = 'pulls'

          # Technically, the upstream approach could be used for both, but it's actually good to have
          # both of them as reference.
          #
          # For upstream pulls, the owner is the authenticated user, otherwise, the repository owner.
          #
          response = if api_interface.upstream?
            unfiltered_response = api_interface.send_request(api_path, multipage: true)

            # VERY weird. From the docs, it's not clear if the user/org is required in the `head` parameter,
            # but:
            #
            # - if it isn't included (eg. `anything`), the parameter is ignored
            # - if it's included (eg. `saveriomiroddi:local_branch_name`), an empty resultset is returned.
            #
            # For this reason, we can't use that param, and have to filter manually.
            #
            unfiltered_response.select { |pr_data| pr_data.fetch('head').fetch('label') == "#{owner}:#{head}" }
          else
            request_params = { head: "#{owner}:#{head}" }

            api_interface.send_request(api_path, params: request_params, multipage: true)
          end

          response.map do |pr_data|
            number = pr_data.fetch('number')
            title = pr_data.fetch('title')
            link = pr_data.fetch('html_url')

            new(number, api_interface, title, link)
          end
        else
          super(api_interface, milestone: milestone, assignee: assignee) do |issue_data|
            issue_data.key?('pull_request')
          end
        end
      end

      # See https://developer.github.com/v3/pulls/#merge-a-pull-request-merge-button
      #
      def merge(merge_method: nil)
        api_path = "pulls/#{number}/merge"
        request_data = { merge_method: } if merge_method

        @api_interface.send_request(api_path, http_method: :put, data: request_data)
      end

      def request_review(reviewers)
        api_path = "pulls/#{number}/requested_reviewers"
        request_data = { reviewers: reviewers }

        @api_interface.send_request(api_path, data: request_data)
      end

      class << self
        private

        def check_list_params!(milestone, assignee, head)
          if (milestone || assignee) && head
            raise "Head can't be specified with milestone or assignee!"
          end
        end
      end
    end
  end
end
