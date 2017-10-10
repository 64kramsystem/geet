# frozen_string_literal: true

require_relative 'api_helper.rb'
require_relative 'pr.rb'

module Geet
  module GitHub
    class Repository
      def initialize(local_repository, api_helper)
        @local_repository = local_repository
        @api_helper = api_helper
      end

      def collaborators
        url = "https://api.github.com/repos/#{@local_repository.owner}/#{@local_repository.repo}/collaborators"
        response = @api_helper.send_request(url, multipage: true)

        response.map { |user_entry| user_entry.fetch('login') }
      end

      def labels
        url = "https://api.github.com/repos/#{@local_repository.owner}/#{@local_repository.repo}/labels"
        response = @api_helper.send_request(url, multipage: true)

        response.map { |label_entry| label_entry['name'] }
      end

      def create_pr(title, description, head: @local_repository.current_head)
        Geet::GitHub::PR.create(title, description, head, @api_helper)
      end
    end
  end
end
