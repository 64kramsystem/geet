# frozen_string_literal: true

module Geet
  module Gitlab
    class PR
      attr_reader :number, :title, :link

      def initialize(number, api_interface, title, link)
        @number = number
        @api_interface = api_interface
        @title = title
        @link = link
      end

      # owner: required only for API compatibility. it's not required; if passed, it's only checked
      #        against the API path to make sure it's correct.
      #
      # See https://docs.gitlab.com/ee/api/merge_requests.html#list-merge-requests
      #
      def self.list(api_interface, milestone: nil, assignee: nil, owner: nil, head: nil)
        api_path = "projects/#{api_interface.path_with_namespace(encoded: true)}/merge_requests"

        check_list_owner!(api_interface, owner) if owner

        request_params = {}
        request_params[:assignee_id] = assignee.id if assignee
        request_params[:milestone] = milestone.title if milestone
        request_params[:source_branch] = head if head

        response = api_interface.send_request(api_path, params: request_params, multipage: true)

        response.map do |issue_data, result|
          number = issue_data.fetch('iid')
          title = issue_data.fetch('title')
          link = issue_data.fetch('web_url')

          new(number, api_interface, title, link)
        end
      end

      # See https://docs.gitlab.com/ee/api/merge_requests.html#accept-mr
      #
      def merge
        api_path = "projects/#{@api_interface.path_with_namespace(encoded: true)}/merge_requests/#{number}/merge"

        @api_interface.send_request(api_path, http_method: :put)
      end

      class << self
        private

        def check_list_owner!(api_interface, owner)
          if !api_interface.path_with_namespace.start_with?("#{owner}/")
            raise "Mismatch owner/API path!: #{owner}<>#{api_interface.path_with_namespace}"
          end
        end
      end
    end # PR
  end # Gitlab
end # Geet
