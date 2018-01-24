# frozen_string_literal: true

require_relative '../helpers/os_helper.rb'
require_relative '../utils/manual_list_selection.rb'
require_relative '../utils/pattern_matching_selection.rb'

module Geet
  module Services
    class CreatePr
      include Geet::Helpers::OsHelper

      MANUAL_LIST_SELECTION_FLAG = '-'.freeze

      def initialize(repository)
        @repository = repository
      end

      # options:
      #   :label_patterns
      #   :reviewer_patterns
      #   :no_open_pr
      #
      def execute(
        title, description, label_patterns: nil, milestone_pattern: nil, reviewer_patterns: nil,
        no_open_pr: nil, output: $stdout, **
      )
        all_labels, all_milestones, all_collaborators = find_all_attribute_entries(
          label_patterns, milestone_pattern, reviewer_patterns, output
        )

        labels = select_entries('label', all_labels, label_patterns, :multiple, :name) if label_patterns
        milestone, _ = select_entries('milestone', all_milestones, milestone_pattern, :single, :title) if milestone_pattern
        reviewers = select_entries('collaborator', all_collaborators, reviewer_patterns, :multiple, nil) if reviewer_patterns

        pr = create_pr(title, description, output)

        edit_pr(pr, labels, milestone, reviewers, output)

        if no_open_pr
          output.puts "PR address: #{pr.link}"
        else
          open_file_with_default_application(pr.link)
        end

        pr
      end

      private

      # Internal actions

      def find_all_attribute_entries(label_patterns, milestone_pattern, reviewer_patterns, output)
        if label_patterns
          output.puts 'Finding labels...'
          labels_thread = Thread.new { @repository.labels }
        end

        if milestone_pattern
          output.puts 'Finding milestone...'
          milestone_thread = Thread.new { @repository.milestones }
        end

        if reviewer_patterns
          output.puts 'Finding collaborators...'
          reviewers_thread = Thread.new { @repository.collaborators }
        end

        labels = labels_thread&.value
        milestones = milestone_thread&.value
        reviewers = reviewers_thread&.value

        [labels, milestones, reviewers]
      end

      def create_pr(title, description, output)
        output.puts 'Creating PR...'

        @repository.create_pr(title, description, @repository.current_branch)
      end

      def edit_pr(pr, labels, milestone, reviewers, output)
        assign_user_thread = assign_authenticated_user(pr, output)

        add_labels_thread = add_labels(pr, labels, output) if labels
        set_milestone_thread = set_milestone(pr, milestone, output) if milestone
        request_review_thread = request_review(pr, reviewers, output) if reviewers

        assign_user_thread.join
        add_labels_thread&.join
        set_milestone_thread&.join
        request_review_thread&.join
      end

      def assign_authenticated_user(pr, output)
        output.puts 'Assigning authenticated user...'

        Thread.new do
          pr.assign_users(@repository.authenticated_user)
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

      def select_entries(entry_type, entries, raw_patterns, selection_type, instance_method)
        if raw_patterns == MANUAL_LIST_SELECTION_FLAG
          Geet::Utils::ManualListSelection.new.select(entry_type, entries, selection_type, instance_method: instance_method)
        else
          Geet::Utils::PatternMatchingSelection.new.select(entry_type, entries, raw_patterns, instance_method: instance_method)
        end
      end
    end
  end
end
