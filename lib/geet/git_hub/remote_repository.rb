# frozen_string_literal: true

require_relative 'api_helper'
require_relative 'gist'
require_relative 'issue'
require_relative 'pr'

module Geet
  module GitHub
    class RemoteRepository
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

      def create_gist(filename, content, description: nil, publik: false)
        Geet::GitHub::Gist.create(@local_repository, filename, content, @api_helper, description: description, publik: publik)
      end

      def create_issue(title, description)
        Geet::GitHub::Issue.create(@local_repository, title, description, @api_helper)
      end

      def list_issues
        Geet::GitHub::AbstractIssue.list(@local_repository, @api_helper, filter: :issue)
      end

      def create_pr(title, description, head: @local_repository.current_head)
        Geet::GitHub::PR.create(@local_repository, title, description, head, @api_helper)
      end

      def list_prs
        Geet::GitHub::AbstractIssue.list(@local_repository, @api_helper, filter: :pr)
      end
    end
  end
end
