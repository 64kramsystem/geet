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
        labels_thread = select_labels(repository, label_patterns) if label_patterns
        reviewers_thread = select_reviewers(repository, reviewer_patterns) if reviewer_patterns

        selected_labels = labels_thread&.join&.value
        reviewers = reviewers_thread&.join&.value

        pr = create_pr(repository, title, description)

        assign_user_thread = assign_authenticated_user(pr, repository)
        add_labels_thread = add_labels(pr, selected_labels) if selected_labels
        request_review_thread = request_review(pr, reviewers) if reviewers

        assign_user_thread.join
        add_labels_thread&.join
        request_review_thread&.join

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

        Thread.new do
          all_labels = repository.labels

          select_entries(all_labels, label_patterns, type: 'labels')
        end
      end

      def select_reviewers(repository, reviewer_patterns)
        puts 'Finding collaborators...'

        Thread.new do
          all_collaborators = repository.collaborators

          select_entries(all_collaborators, reviewer_patterns, type: 'collaborators')
        end
      end

      def create_pr(repository, title, description)
        puts 'Creating PR...'

        repository.create_pr(title, description, repository.current_branch)
      end

      def assign_authenticated_user(pr, repository)
        puts 'Assigning authenticated user...'

        Thread.new do
          pr.assign_users(repository.authenticated_user)
        end
      end

      def add_labels(pr, selected_labels)
        puts "Adding labels #{selected_labels.join(', ')}..."

        Thread.new do
          pr.add_labels(selected_labels)
        end
      end

      def request_review(pr, reviewers)
        puts "Requesting review from #{reviewers.join(', ')}..."

        Thread.new do
          pr.request_review(reviewers)
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
