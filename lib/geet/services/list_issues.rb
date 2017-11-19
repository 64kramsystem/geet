# frozen_string_literal: true

module Geet
  module Services
    class ListIssues
      def execute(repository, output: $stdout)
        issues = repository.issues

        issues.each do |issue|
          output.puts "#{issue.number}. #{issue.title} (#{issue.link})"
        end
      end
    end
  end
end
