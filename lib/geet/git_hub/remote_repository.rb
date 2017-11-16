# frozen_string_literal: true

require_relative 'abstract_issue'
require_relative 'api_helper'
require_relative 'collaborator'
require_relative 'gist'
require_relative 'issue'
require_relative 'label'
require_relative 'milestone'
require_relative 'pr'

module Geet
  module GitHub
    class RemoteRepository
      def initialize(api_helper)
        @api_helper = api_helper
      end

      def collaborators
        Geet::GitHub::Collaborator.list(@api_helper)
      end

      def labels
        Geet::GitHub::Label.list(@api_helper)
      end

      def create_gist(filename, content, description: nil, publik: false)
        Geet::GitHub::Gist.create(filename, content, @api_helper, description: description, publik: publik)
      end

      def create_issue(title, description)
        Geet::GitHub::Issue.create(title, description, @api_helper)
      end

      def abstract_issues(milestone: nil)
        Geet::GitHub::AbstractIssue.list(@api_helper, milestone: milestone)
      end

      def issues
        Geet::GitHub::Issue.list(@api_helper)
      end

      def milestone(number)
        Geet::GitHub::Milestone.find(number, @api_helper)
      end

      def milestones
        Geet::GitHub::Milestone.list(@api_helper)
      end

      def create_pr(title, description, head)
        Geet::GitHub::PR.create(title, description, head, @api_helper)
      end

      def prs(head: nil)
        Geet::GitHub::PR.list(@api_helper, head: head)
      end
    end
  end
end
