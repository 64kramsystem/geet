# frozen_string_literal: true

# require_relative '../helpers/os_helper.rb'
# require_relative '../git/repository.rb'

module Geet
  module Services
    class ListIssues
      def execute(repository)
        issues = repository.list_issues

        issues.each do |issue|
          puts "#{issue.number}. #{issue.title} (#{issue.link})"
        end
      end
    end
  end
end
