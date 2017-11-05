# frozen_string_literal: true

require_relative '../helpers/os_helper.rb'
require_relative '../git/repository.rb'

module Geet
  module Services
    class CreatePr
      include Geet::Helpers::OsHelper

      # options:
      #   :label_patterns
      #   :reviewer_patterns
      #   :no_open_pr
      #
      def execute(repository, title, description, label_patterns: nil, reviewer_patterns: nil, no_open_pr: nil, **)
        selected_labels = select_labels(repository, label_patterns]) if label_patterns
        reviewers = select_reviewers(repository, reviewer_patterns]) if reviewer_patterns

        pr = create_pr(repository, title, description)

        assign_user(pr, repository)
        add_labels(pr, selected_labels) if selected_labels
        request_review(pr, reviewers) if reviewers

        if no_open_pr
          puts "PR address: #{pr.link}"
        else
          os_open(pr.link)
        end
      end

      private

      # Internal actions

      def select_labels(repository, label_patterns)
        puts 'Finding labels...'

        all_labels = repository.labels

        select_entries(all_labels, label_patterns, type: 'labels')
      end

      def select_reviewers(repository, reviewer_patterns)
        puts 'Finding collaborators...'

        all_collaborators = repository.collaborators

        select_entries(all_collaborators, reviewer_patterns, type: 'collaborators')
      end

      def create_pr(repository, title, description)
        puts 'Creating PR...'

        pr = repository.create_pr(title, description, repository.current_head)
      end

      def assign_user(pr, repository)
        puts 'Assigning authenticated user...'

        pr.assign_user(repository.authenticated_user)
      end

      def add_labels(pr, selected_labels)
        puts 'Adding labels...'

        pr.add_labels(selected_labels)

        puts '- labels added: ' + selected_labels.join(', ')
      end

      def request_review(pr, reviewers)
        puts 'Requesting review...'

        pr.request_review(reviewers)

        puts '- review requested to: ' + reviewers.join(', ')
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
