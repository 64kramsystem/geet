# frozen_string_literal: true

require_relative 'abstract_create_issue'

module Geet
  module Services
    class CreateIssue < AbstractCreateIssue
      # options:
      #   :labels
      #   :milestone:     number or description pattern.
      #   :assignees
      #   :no_open_issue
      #
      def execute(
          title, description,
          labels: nil, milestone: nil, assignees: nil, no_open_issue: nil,
          output: $stdout, **
      )
        all_labels_thread = find_attribute_entries(:labels, output) if labels
        all_milestones_thread = find_attribute_entries(:milestones, output) if milestone
        all_collaborators_thread = find_attribute_entries(:collaborators, output) if assignees

        selected_labels = select_entries('label', all_labels_thread.value, labels, :name) if labels
        selected_milestone = select_entry('milestone', all_milestones_thread.value, milestone, :title) if milestone
        selected_assignees = select_entries('assignee', all_collaborators_thread.value, assignees, nil) if assignees

        issue = create_issue(title, description, output)

        edit_issue(issue, selected_labels, selected_milestone, selected_assignees, output)

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
    end
  end
end
