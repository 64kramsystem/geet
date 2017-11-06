# frozen_string_literal: true

require_relative '../helpers/os_helper.rb'
require_relative '../git/repository.rb'

module Geet
  module Services
    class CreateIssue
      include Geet::Helpers::OsHelper

      # options:
      #   :label_patterns
      #   :assignee_patterns
      #   :no_open_issue
      #
      def execute(repository, title, description, label_patterns: nil, assignee_patterns: nil, no_open_issue: nil, **)
        labels_thread = select_labels(repository, label_patterns) if label_patterns
        assignees_thread = select_assignees(repository, assignee_patterns) if assignee_patterns

        selected_labels = labels_thread&.join&.value
        assignees = assignees_thread&.join&.value

        puts 'Creating the issue...'

        issue = repository.create_issue(title, description)

        add_labels_thread = add_labels(issue, selected_labels) if selected_labels

        if assignees
          assign_users_thread = assign_users(issue, assignees)
        else
          assign_users_thread = assign_authenticated_user(repository, issue)
        end

        add_labels_thread&.join
        assign_users_thread.join

        if no_open_issue
          puts "Issue address: #{issue.link}"
        else
          os_open(issue.link)
        end
      end

      private

      # Internal actions

      def select_labels(repository, label_patterns)
        puts 'Finding labels...'

        Thread.new do
          all_labels = repository.labels

          select_entries(all_labels, label_patterns, type: 'labels')
        end
      end

      def select_assignees(repository, assignee_patterns)
        puts 'Finding collaborators...'

        Thread.new do
          all_collaborators = repository.collaborators

          select_entries(all_collaborators, assignee_patterns, type: 'collaborators')
        end
      end

      def add_labels(issue, selected_labels)
        puts "Adding labels #{selected_labels.join(', ')}..."

        Thread.new do
          issue.add_labels(selected_labels)
        end
      end

      def assign_users(issue, users)
        puts "Assigning users #{users.join(', ')}..."

        Thread.new do
          issue.assign_users(users)
        end
      end

      def assign_authenticated_user(repository, issue)
        puts 'Assigning authenticated user...'

        Thread.new do
          issue.assign_users(repository.authenticated_user)
        end
      end

      # Generic helpers

      def select_entries(entries, raw_patterns, type: 'entries')
        patterns = raw_patterns.split(',')

        patterns.map do |pattern|
          entries_found = entries.select { |label| label =~ /#{pattern}/i }

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
