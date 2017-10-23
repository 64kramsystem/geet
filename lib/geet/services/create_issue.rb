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
      def execute(repository, title, description, options = {})
        if options[:label_patterns]
          puts 'Finding labels...'

          all_labels = repository.labels
          selected_labels = select_entries(all_labels, options[:label_patterns], type: 'labels')
        end

        if options[:assignee_patterns]
          puts 'Finding collaborators...'

          all_collaborators = repository.collaborators
          assignees = select_entries(all_collaborators, options[:assignee_patterns], type: 'collaborators')
        end

        puts 'Creating the issue...'

        issue = repository.create_issue(title, description)

        if selected_labels
          puts 'Adding labels...'

          issue.add_labels(selected_labels)

          puts '- labels added: ' + selected_labels.join(', ')
        end

        if assignees
          puts 'Assigning users...'

          issue.assign_user(assignees)

          puts '- assigned: ' + assignees.join(', ')
        else
          issue.assign_user(repository.authenticated_user)
        end

        if options[:no_open_issue]
          puts "Issue address: #{issue.link}"
        else
          os_open(issue.link)
        end
      end

      private

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
            raise "Multiple #{type} found for pattern #{pattern.inspect}: #{labels_found}"
          end
        end
      end
    end
  end
end
