# frozen_string_literal: true

require_relative '../helpers/os_helper.rb'

module Geet
  module Services
    class CreateIssue
      include Geet::Helpers::OsHelper

      # options:
      #   :label_patterns
      #   :milestone_pattern:     number or description pattern.
      #   :assignee_patterns
      #   :no_open_issue
      #
      def execute(
          repository, title, description,
          label_patterns: nil, milestone_pattern: nil, assignee_patterns: nil, no_open_issue: nil,
          output: $stdout, **
      )
        labels_thread = select_labels(repository, label_patterns, output) if label_patterns
        milestone_thread = find_milestone(repository, milestone_pattern, output) if milestone_pattern
        assignees_thread = select_assignees(repository, assignee_patterns, output) if assignee_patterns

        selected_labels = labels_thread&.join&.value
        assignees = assignees_thread&.join&.value
        milestone = milestone_thread&.join&.value

        output.puts 'Creating the issue...'

        issue = repository.create_issue(title, description)

        add_labels_thread = add_labels(issue, selected_labels, output) if selected_labels
        set_milestone_thread = set_milestone(issue, milestone, output) if milestone

        if assignees
          assign_users_thread = assign_users(issue, assignees, output)
        else
          assign_users_thread = assign_authenticated_user(repository, issue, output)
        end

        add_labels_thread&.join
        set_milestone_thread&.join
        assign_users_thread.join

        if no_open_issue
          output.puts "Issue address: #{issue.link}"
        else
          open_file_with_default_application(issue.link)
        end

        issue
      end

      private

      # Internal actions

      def select_labels(repository, label_patterns, output)
        output.puts 'Finding labels...'

        Thread.new do
          all_labels = repository.labels

          select_entries(all_labels, label_patterns, type: 'labels', instance_method: :name)
        end
      end

      def find_milestone(repository, milestone_pattern, output)
        output.puts 'Finding milestone...'

        Thread.new do
          all_milestones = repository.milestones

          select_entries(all_milestones, milestone_pattern, type: 'milestones', instance_method: :title).first
        end
      end

      def select_assignees(repository, assignee_patterns, output)
        output.puts 'Finding collaborators...'

        Thread.new do
          all_collaborators = repository.collaborators

          select_entries(all_collaborators, assignee_patterns, type: 'collaborators')
        end
      end

      def add_labels(issue, selected_labels, output)
        labels_list = selected_labels.map(&:name).join(', ')

        output.puts "Adding labels #{labels_list}..."

        Thread.new do
          issue.add_labels(selected_labels.map(&:name))
        end
      end

      def set_milestone(issue, milestone, output)
        output.puts "Setting milestone #{milestone.title}..."

        Thread.new do
          issue.edit(milestone: milestone.number)
        end
      end

      def assign_users(issue, users, output)
        output.puts "Assigning users #{users.join(', ')}..."

        Thread.new do
          issue.assign_users(users)
        end
      end

      def assign_authenticated_user(repository, issue, output)
        output.puts 'Assigning authenticated user...'

        Thread.new do
          issue.assign_users(repository.authenticated_user)
        end
      end

      # Generic helpers

      def select_entries(entries, raw_patterns, type: 'entries', instance_method: nil)
        patterns = raw_patterns.split(',')

        patterns.map do |pattern|
          entries_found = entries.select do |entry|
            entry = entry.send(instance_method) if instance_method
            entry =~ /#{pattern}/i
          end

          case entries_found.size
          when 1
            entries_found.first
          when 0
            raise "No #{type} found for pattern: #{pattern.inspect}"
          else
            raise "Multiple #{type} found for pattern #{pattern.inspect}: #{entries_found}"
          end
        end
      end
    end
  end
end
