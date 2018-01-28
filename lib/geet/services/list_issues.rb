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
          all_collaborators_thread = find_attribute_entries(:collaborators, output)
          selected_assignee = select_entry('assignee', all_collaborators_thread.value, assignee, nil)
        end

        issues = @repository.issues(assignee: selected_assignee)

        issues.each do |issue|
          output.puts "#{issue.number}. #{issue.title} (#{issue.link})"
        end
      end

      private

      def find_attribute_entries(repository_call, output)
        output.puts "Finding #{repository_call}..."

        Thread.new do
          entries = @repository.send(repository_call)

          raise "No #{repository_call} found!" if entries.empty?

          entries
        end
      end
    end
  end
end
