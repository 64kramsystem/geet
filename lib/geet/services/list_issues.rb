# frozen_string_literal: true

require_relative '../helpers/selection_helper.rb'

module Geet
  module Services
    class ListIssues
      include Geet::Helpers::SelectionHelper

      def initialize(repository)
        @repository = repository
      end

      def execute(assignee: nil, output: $stdout, **)
        if assignee
          all_collaborators = find_all_collaborator_entries(output)
          selected_assignee = select_entry('assignee', all_collaborators, assignee, nil)
        end

        issues = @repository.issues(assignee: selected_assignee)

        issues.each do |issue|
          output.puts "#{issue.number}. #{issue.title} (#{issue.link})"
        end
      end

      private

      def find_all_collaborator_entries(output)
        output.puts 'Finding collaborators...'

        collaborators_thread = Thread.new do
          @repository.collaborators
        end

        collaborators_thread.value
      end
    end
  end
end
