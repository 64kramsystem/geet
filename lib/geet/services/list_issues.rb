# frozen_string_literal: true

require_relative '../utils/attributes_selection_manager'

module Geet
  module Services
    class ListIssues
      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end

      def execute(assignee: nil, **)
        selected_assignee = find_and_select_attributes(assignee) if assignee

        issues = @repository.issues(assignee: selected_assignee)

        issues.each do |issue|
          @out.puts "#{issue.number}. #{issue.title} (#{issue.link})"
        end
      end

      private

      def find_and_select_attributes(assignee)
        selection_manager = Geet::Utils::AttributesSelectionManager.new(@repository, out: @out)

        selection_manager.add_attribute(:collaborators, 'assignee', assignee, :single, name_method: :username)

        selection_manager.select_attributes.map(&:username).first
      end
    end
  end
end
