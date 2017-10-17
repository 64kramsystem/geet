# frozen_string_literal: true

require_relative 'abstract_issue'

module Geet
  module GitHub
    class Issue < AbstractIssue
      def self.create(repository, title, description, api_helper)
        request_address = "#{api_helper.repo_link}/issues"
        request_data = { title: title, body: description, base: 'master' }

        response = api_helper.send_request(request_address, data: request_data)

        issue_number = response.fetch('number')

        new(repository, issue_number, api_helper)
      end

      # Returns an array of Struct(:number, :title); once this workflow is extended,
      # the struct will likely be converted to a standard class.
      #
      # See https://developer.github.com/v3/issues/#list-issues-for-a-repository
      #
      def self.list(repository, api_helper)
        request_address = "#{api_helper.repo_link}/issues"

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
        "https://github.com/#{@repository.owner}/#{@repository.repo}/issues/#{@issue_number}"
      end
    end
  end
end
