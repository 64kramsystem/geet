# frozen_string_literal: true

module Geet
  module Services
    class ListIssues
      def initialize(repository)
        @repository = repository
      end

      def execute(assignee_pattern: nil, output: $stdout, **)
        assignee_thread = find_assignee(assignee_pattern, output) if assignee_pattern

        assignee = assignee_thread&.join&.value

        issues = @repository.issues(assignee: assignee)

        issues.each do |issue|
          output.puts "#{issue.number}. #{issue.title} (#{issue.link})"
        end
      end

      private

      def find_assignee(assignee_pattern, output)
        output.puts 'Finding assignee...'

        Thread.new do
          collaborators = @repository.collaborators
          collaborator = collaborators.find { |collaborator| collaborator =~ /#{assignee_pattern}/i }
          collaborator || raise("No collaborator found for pattern: #{assignee_pattern.inspect}")
        end
      end
    end
  end
end
