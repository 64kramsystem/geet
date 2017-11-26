# frozen_string_literal: true

module Geet
  module Gitlab
    class Issue
      attr_reader :number, :title, :link

      def initialize(number, title, link)
        @number = number
        @title = title
        @link = link
      end

      def self.list(api_interface)
        api_path = "projects/#{api_interface.path_with_namespace(encoded: true)}/issues"

        response = api_interface.send_request(api_path, multipage: true)

        response.each_with_object([]) do |issue_data, result|
          number = issue_data.fetch('iid')
          title = issue_data.fetch('title')
          link = issue_data.fetch('web_url')

          result << new(number, title, link)
        end
      end
    end
  end
end
