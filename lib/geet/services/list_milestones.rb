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
        all_milestone_entries = find_all_milestone_entries(milestones)

        @out.puts

        all_milestone_entries.each do |milestone, milestone_entries|
          @out.puts milestone_description(milestone)

          milestone_entries.fetch(:issues).each do |issue|
            @out.puts "  #{issue.number}. #{issue.title} (#{issue.link})"
          end

          milestone_entries.fetch(:prs).each do |pr|
            @out.puts "  #{pr.number}. #{pr.title} (#{pr.link})"
          end
        end

        all_milestone_entries.keys
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

      # Returns the structure:
      #
      # { milestone => {issues: [...], prs: [...]}}
      #
      def find_all_milestone_entries(milestones)
        @out.puts 'Finding issues and PRs...'

        all_milestone_entries = {}
        all_threads = []

        milestones.each_with_object(Mutex.new) do |milestone, mutex|
          all_milestone_entries[milestone] = {}

          all_threads << Thread.new do
            issues = @repository.issues(milestone: milestone)

            mutex.synchronize do
              all_milestone_entries[milestone][:issues] = issues
            end
          end

          all_threads << Thread.new do
            prs = @repository.prs(milestone: milestone)

            mutex.synchronize do
              all_milestone_entries[milestone][:prs] = prs
            end
          end
        end

        all_threads.map(&:join)

        all_milestone_entries
      end
    end
  end
end
