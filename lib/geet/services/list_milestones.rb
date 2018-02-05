# frozen_string_literal: true

module Geet
  module Services
    class ListMilestones
      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end

      def execute
        milestones = find_milestones
        issues_by_milestone_number = find_milestone_issues(milestones)

        @out.puts

        milestones.each do |milestone|
          @out.puts milestone_description(milestone)

          milestone_issues = issues_by_milestone_number[milestone.number]

          milestone_issues.each do |issue|
            @out.puts "  #{issue.number}. #{issue.title} (#{issue.link})"
          end
        end
      end

      private

      # Not included in the Milestone class because descriptions (which will be customizable)
      # are considered formatters, conceptually external to the class.
      def milestone_description(milestone)
        description = "#{milestone.number}. #{milestone.title}"
        description += " (due #{milestone.due_on})" if milestone.due_on
        description
      end

      def find_milestones
        @out.puts 'Finding milestones...'

        @repository.milestones
      end

      def find_milestone_issues(milestones)
        @out.puts 'Finding issues...'

        # Interestingly, on MRI, concurrent hash access is not a problem without mutex,
        # since due to the GIL, only one thread at a time will actually access it.
        issues_by_milestone_number = {}
        mutex = Mutex.new

        issue_threads = milestones.map do |milestone|
          Thread.new do
            issues = @repository.abstract_issues(milestone: milestone.number)

            mutex.synchronize do
              issues_by_milestone_number[milestone.number] = issues
            end
          end
        end

        issue_threads.map(&:join)

        issues_by_milestone_number
      end
    end
  end
end
