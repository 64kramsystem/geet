# frozen_string_literal: true

require_relative 'abstract_create_issue'
require_relative '../shared/repo_permissions'
require_relative '../shared/selection'

module Geet
  module Services
    class CreateIssue < AbstractCreateIssue
      include Geet::Shared::RepoPermissions
      include Geet::Shared::Selection

      # options:
      #   :labels
      #   :milestone:     number or description pattern.
      #   :assignees
      #   :no_open_issue
      #
      def execute(
          title, description,
          labels: nil, milestone: nil, assignees: nil, no_open_issue: nil,
          **
      )
        # Inefficient (in worst case, triples the pre issue creation waiting time: #is_collaborator?,
        # #has_permissions?, and the attributes batch), but not trivial to speed up. Not difficult
        # either, but currently not worth spending time.
        #
        # Theoretically, #is_collaborator? could be skipped, but this is cleaner.
        user_has_write_permissions = @repository.authenticated_user.is_collaborator? &&
                                     @repository.authenticated_user.has_permission?(PERMISSION_WRITE)

        if user_has_write_permissions
          selected_labels, selected_milestone, selected_assignees = find_and_select_attributes(labels, milestone, assignees)
        end

        issue = create_issue(title, description)

        if user_has_write_permissions
          edit_issue(issue, selected_labels, selected_milestone, selected_assignees)
        end

        if no_open_issue
          @out.puts "Issue address: #{issue.link}"
        else
          open_file_with_default_application(issue.link)
        end

        issue
      end

      private

      # Internal actions

      def find_and_select_attributes(labels, milestone, assignees)
        selection_manager = Geet::Utils::AttributesSelectionManager.new(@repository, out: @out)

        selection_manager.add_attribute(:labels, 'label', labels, SELECTION_MULTIPLE, name_method: :name) if labels
        selection_manager.add_attribute(:milestones, 'milestone', milestone, SELECTION_SINGLE, name_method: :title) if milestone
        selection_manager.add_attribute(:collaborators, 'assignee', assignees, SELECTION_MULTIPLE, name_method: :username) if assignees

        selection_manager.select_attributes
      end

      def create_issue(title, description)
        @out.puts 'Creating the issue...'

        issue = @repository.create_issue(title, description)
      end

      def edit_issue(issue, labels, milestone, assignees)
        # labels can be nil (parameter not passed) or empty array (parameter passed, but nothing
        # selected)
        add_labels_thread = add_labels(issue, labels) if labels && !labels.empty?
        set_milestone_thread = set_milestone(issue, milestone) if milestone

        # same considerations as above, but with additional upstream case.
        if assignees
          assign_users_thread = assign_users(issue, assignees) if !assignees.empty?
        elsif !@repository.upstream?
          assign_users_thread = assign_authenticated_user(issue)
        end

        add_labels_thread&.join
        set_milestone_thread&.join
        assign_users_thread&.join
      end

      def add_labels(issue, selected_labels)
        labels_list = selected_labels.map(&:name).join(', ')

        @out.puts "Adding labels #{labels_list}..."

        Thread.new do
          issue.add_labels(selected_labels.map(&:name))
        end
      end

      def set_milestone(issue, milestone)
        @out.puts "Setting milestone #{milestone.title}..."

        Thread.new do
          issue.edit(milestone: milestone.number)
        end
      end

      def assign_users(issue, users)
        usernames = users.map(&:username)

        @out.puts "Assigning users #{usernames.join(', ')}..."

        Thread.new do
          issue.assign_users(usernames)
        end
      end

      def assign_authenticated_user(issue)
        @out.puts 'Assigning authenticated user...'

        Thread.new do
          issue.assign_users(@repository.authenticated_user.username)
        end
      end
    end
  end
end
