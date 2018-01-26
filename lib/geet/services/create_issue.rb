# frozen_string_literal: true

require 'tmpdir'
require_relative '../helpers/os_helper.rb'
require_relative '../helpers/selection_helper.rb'

module Geet
  module Services
    class CreateIssue
      include Geet::Helpers::OsHelper
      include Geet::Helpers::SelectionHelper

      SUMMARY_BACKUP_FILENAME = File.join(Dir.tmpdir, 'last_geet_edited_summary.md')

      def initialize(repository)
        @repository = repository
      end

      # options:
      #   :label_patterns
      #   :milestone_pattern:     number or description pattern.
      #   :assignee_patterns
      #   :no_open_issue
      #
      def execute(
          title, description,
          label_patterns: nil, milestone_pattern: nil, assignee_patterns: nil, no_open_issue: nil,
          output: $stdout, **
      )
        all_labels, all_milestones, all_collaborators = find_all_attribute_entries(
          label_patterns, milestone_pattern, assignee_patterns, output
        )

        labels = select_entries('label', all_labels, label_patterns, :multiple, :name) if label_patterns
        milestone, _ = select_entries('milestone', all_milestones, milestone_pattern, :single, :title) if milestone_pattern
        assignees = select_entries('assignee', all_collaborators, assignee_patterns, :multiple, nil) if assignee_patterns

        issue = create_issue(title, description, output)

        edit_issue(issue, labels, milestone, assignees, output)

        if no_open_issue
          output.puts "Issue address: #{issue.link}"
        else
          open_file_with_default_application(issue.link)
        end

        issue
      rescue => error
        save_summary(title, description, output) if title
        raise
      end

      private

      # Internal actions

      def find_all_attribute_entries(label_patterns, milestone_pattern, assignee_patterns, output)
        if label_patterns
          output.puts 'Finding labels...'
          labels_thread = Thread.new { @repository.labels }
        end

        if milestone_pattern
          output.puts 'Finding milestone...'
          milestone_thread = Thread.new { @repository.milestones }
        end

        if assignee_patterns
          output.puts 'Finding collaborators...'
          assignees_thread = Thread.new { @repository.collaborators }
        end

        labels = labels_thread&.value
        milestones = milestone_thread&.value
        assignees = assignees_thread&.value

        raise "No labels found!" if label_patterns && labels.empty?
        raise "No milestones found!" if milestone_pattern && milestones.empty?
        raise "No collaborators found!" if assignee_patterns && assignees.empty?

        [labels, milestones, assignees]
      end

      def create_issue(title, description, output)
        output.puts 'Creating the issue...'

        issue = @repository.create_issue(title, description)
      end

      def edit_issue(issue, labels, milestone, assignees, output)
        # labels can be nil (parameter not passed) or empty array (parameter passed, but nothing
        # selected)
        add_labels_thread = add_labels(issue, labels, output) if labels && !labels.empty?
        set_milestone_thread = set_milestone(issue, milestone, output) if milestone

        # same considerations as above, but with additional upstream case.
        if assignees
          assign_users_thread = assign_users(issue, assignees, output) if !assignees.empty?
        elsif !@repository.upstream?
          assign_users_thread = assign_authenticated_user(issue, output)
        end

        add_labels_thread&.join
        set_milestone_thread&.join
        assign_users_thread&.join
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

      def assign_authenticated_user(issue, output)
        output.puts 'Assigning authenticated user...'

        Thread.new do
          issue.assign_users(@repository.authenticated_user)
        end
      end

      def save_summary(title, description, output)
        summary = "#{title}\n\n#{description}".strip + "\n"

        IO.write(SUMMARY_BACKUP_FILENAME, summary)

        output.puts "Error! Saved summary to #{SUMMARY_BACKUP_FILENAME}"
      end
    end
  end
end
