# frozen_string_literal: true

require_relative '../utils/attributes_selection_manager'

module Geet
  module Services
    class ListIssues
      def initialize(repository)
        @repository = repository
      end

      def execute(assignee: nil, output: $stdout, **)
        selected_assignee = find_and_select_attributes(assignee, output) if assignee

        issues = @repository.issues(assignee: selected_assignee)

        issues.each do |issue|
          output.puts "#{issue.number}. #{issue.title} (#{issue.link})"
        end
      end

      private

      def find_and_select_attributes(assignee, output)
        selection_manager = Geet::Utils::AttributesSelectionManager.new(@repository, output)

        selection_manager.add_attribute(:collaborators, 'assignee', assignee, :single)

        selection_manager.select_attributes
      end
    end
  end
end
