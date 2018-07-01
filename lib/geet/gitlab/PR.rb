# frozen_string_literal: true

module Geet
  module Gitlab
    class PR
      attr_reader :number, :title, :link

      def initialize(number, title, link)
        @number = number
        @title = title
        @link = link
      end

      # See https://docs.gitlab.com/ee/api/merge_requests.html#list-merge-requests
      #
      def self.list(api_interface, milestone: nil, assignee: nil, head: nil)
        raise ":head parameter currently unsupported!" if head

        api_path = "projects/#{api_interface.path_with_namespace(encoded: true)}/merge_requests"

        request_params = {}
        request_params[:assignee_id] = assignee.id if assignee
        request_params[:milestone] = milestone.title if milestone

        response = api_interface.send_request(api_path, params: request_params, multipage: true)

        response.map do |issue_data, result|
          number = issue_data.fetch('iid')
          title = issue_data.fetch('title')
          link = issue_data.fetch('web_url')

          new(number, title, link)
        end
      end
    end # PR
  end # Gitlab
end # Geet
