# frozen_string_literal: true

require_relative '../helpers/os_helper.rb'

module Geet
  module Services
    class CreatePr
      include Geet::Helpers::OsHelper

      # options:
      #   :label_patterns
      #   :reviewer_patterns
      #   :no_open_pr
      #
      def execute(
        repository, title, description, label_patterns: nil, milestone_pattern: nil, reviewer_patterns: nil,
        no_open_pr: nil, output: $stdout, **
      )
        labels_thread = select_labels(repository, label_patterns, output) if label_patterns
        milestone_thread = find_milestone(repository, milestone_pattern, output) if milestone_pattern
        reviewers_thread = select_reviewers(repository, reviewer_patterns, output) if reviewer_patterns

        selected_labels = labels_thread&.join&.value
        reviewers = reviewers_thread&.join&.value
        milestone = milestone_thread&.join&.value

        pr = create_pr(repository, title, description, output)

        assign_user_thread = assign_authenticated_user(pr, repository, output)
        add_labels_thread = add_labels(pr, selected_labels, output) if selected_labels
        set_milestone_thread = set_milestone(pr, milestone, output) if milestone
        request_review_thread = request_review(pr, reviewers, output) if reviewers

        assign_user_thread.join
        add_labels_thread&.join
        set_milestone_thread&.join
        request_review_thread&.join

        if no_open_pr
          output.puts "PR address: #{pr.link}"
        else
          os_open(pr.link)
        end

        pr
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
          if milestone_pattern =~ /\A\d+\Z/
            repository.milestone(milestone_pattern)
          else
            all_milestones = repository.milestones

            select_entries(all_milestones, milestone_pattern, type: 'milestones', instance_method: :title).first
          end
        end
      end

      def select_reviewers(repository, reviewer_patterns, output)
        output.puts 'Finding collaborators...'

        Thread.new do
          all_collaborators = repository.collaborators

          select_entries(all_collaborators, reviewer_patterns, type: 'collaborators')
        end
      end

      def create_pr(repository, title, description, output)
        output.puts 'Creating PR...'

        repository.create_pr(title, description, repository.current_branch)
      end

      def assign_authenticated_user(pr, repository, output)
        output.puts 'Assigning authenticated user...'

        Thread.new do
          pr.assign_users(repository.authenticated_user)
        end
      end

      def add_labels(pr, selected_labels, output)
        labels_list = selected_labels.map(&:name).join(', ')

        output.puts "Adding labels #{labels_list}..."

        Thread.new do
          pr.add_labels(selected_labels.map(&:name))
        end
      end

      def set_milestone(pr, milestone, output)
        output.puts "Setting milestone #{milestone.title}..."

        Thread.new do
          pr.edit(milestone: milestone.number)
        end
      end

      def request_review(pr, reviewers, output)
        output.puts "Requesting review from #{reviewers.join(', ')}..."

        Thread.new do
          pr.request_review(reviewers)
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
