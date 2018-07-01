# frozen_string_literal: true

module Geet
  module Services
    class ListMilestones
      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end

      # In the Gitlab model, a PR is not an abstract issue, so we use a vague `entry` name.
      #
      def execute
        milestones = find_milestones
        all_entries = find_milestone_entries(milestones)

        @out.puts

        milestones.each do |milestone|
          @out.puts milestone_description(milestone)

          milestone_entries = all_entries[milestone.number]

          milestone_entries = sort_milestone_entries(milestone_entries)

          milestone_entries.each do |entry|
            @out.puts "  #{entry.number}. #{entry.title} (#{entry.link})"
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

      def find_milestone_entries(milestones)
        @out.puts 'Finding issues and PRs...'

        entries_by_milestone_number = milestones.map { |milestone| [milestone.number, []] }.to_h
        entries_threads = []

        milestones.each_with_object(Mutex.new) do |milestone, mutex|
          entries_threads << Thread.new do
            issues = @repository.issues(milestone: milestone.number)

            mutex.synchronize do
              entries_by_milestone_number[milestone.number].concat(issues)
            end
          end

          entries_threads << Thread.new do
            prs = @repository.prs(milestone: milestone.number)

            mutex.synchronize do
              entries_by_milestone_number[milestone.number].concat(prs)
            end
          end
        end

        entries_threads.map(&:join)

        entries_by_milestone_number
      end

      def sort_milestone_entries(milestone_entries)
        milestone_entries.sort do |entry, other_entry|
          # Put issues before PRs, and for same type, sort by number.
          if issue?(entry) && pr?(other_entry)
            -1
          elsif pr?(entry) && issue?(other_entry)
            1
          else
            entry.number <=> entry.number
          end
        end
      end

      private

      # The classes can be from any namespace, so we can't test the class itself.
      def pr?(entry)
        entry.class.name[/[^:]+$/] == 'PR'
      end

      def issue?(entry)
        entry.class.name[/[^:]+$/] == 'Issue'
      end
    end
  end
end
