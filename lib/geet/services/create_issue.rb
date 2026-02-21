# frozen_string_literal: true
# typed: strict

module Geet
  module Services
    class CreateIssue < AbstractCreateIssue
      extend T::Sig

      include Geet::Shared::RepoPermissions
      include Geet::Shared::Selection

      sig {
        params(
          title: String,
          description: String,
          labels: T.nilable(String),
          milestone: T.nilable(String), # Number or description pattern
          assignees: T.nilable(String),
          open_browser: T::Boolean
        ).returns(Github::Issue)
      }
      def execute(
          title, description,
          labels: nil, milestone: nil, assignees: nil, open_browser: false
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

        if open_browser
          open_file_with_default_application(issue.link)
        else
          @out.puts "Issue address: #{issue.link}"
        end

        issue
      end

      private

      # Internal actions

      sig {
        params(
          labels: T.nilable(String),
          milestone: T.nilable(String),
          assignees: T.nilable(String)
        ).returns([
          T.nilable(T::Array[Github::Label]),
          T.nilable(Github::Milestone),
          T.nilable(T::Array[Github::User]),
        ])
      }
      def find_and_select_attributes(labels, milestone, assignees)
        selection_manager = Geet::Utils::AttributesSelectionManager.new(@repository, out: @out)

        selection_manager.add_attribute(:labels, "label", labels, SELECTION_MULTIPLE, name_method: :name) if labels
        selection_manager.add_attribute(:milestones, "milestone", milestone, SELECTION_SINGLE, name_method: :title) if milestone
        selection_manager.add_attribute(:collaborators, "assignee", assignees, SELECTION_MULTIPLE, name_method: :username) if assignees

        selected_attributes = selection_manager.select_attributes

        selected_labels = T.cast(selected_attributes.shift, T.nilable(T::Array[Github::Label])) if labels
        selected_milestone = T.cast(selected_attributes.shift, T.nilable(Github::Milestone)) if milestone
        selected_assignees = T.cast(selected_attributes.shift, T.nilable(T::Array[Github::User])) if assignees

        [selected_labels, selected_milestone, selected_assignees]
      end

      sig {
        params(
          title: String,
          description: String
        ).returns(Github::Issue)
      }
      def create_issue(title, description)
        @out.puts "Creating the issue..."

        issue = @repository.create_issue(title, description)
      end

      sig {
        params(
          issue: Github::Issue,
          labels: T.nilable(T::Array[Github::Label]),
          milestone: T.nilable(Github::Milestone),
          assignees: T.nilable(T::Array[Github::User])
        ).void
      }
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

      sig {
        params(
          issue: Github::Issue,
          selected_labels: T::Array[Github::Label]
        ).returns(Thread)
      }
      def add_labels(issue, selected_labels)
        labels_list = selected_labels.map(&:name).join(", ")

        @out.puts "Adding labels #{labels_list}..."

        Thread.new do
          issue.add_labels(selected_labels.map(&:name))
        end
      end

      sig {
        params(
          issue: Github::Issue,
          milestone: Github::Milestone
        ).returns(Thread)
      }
      def set_milestone(issue, milestone)
        @out.puts "Setting milestone #{milestone.title}..."

        Thread.new do
          issue.edit(milestone: milestone.number)
        end
      end

      sig {
        params(
          issue: Github::Issue,
          users: T::Array[Github::User]
        ).returns(Thread)
      }
      def assign_users(issue, users)
        usernames = users.map(&:username)

        @out.puts "Assigning users #{usernames.join(', ')}..."

        Thread.new do
          issue.assign_users(usernames)
        end
      end

      sig {
        params(
          issue: Github::Issue
        ).returns(Thread)
      }
      def assign_authenticated_user(issue)
        @out.puts "Assigning authenticated user..."

        Thread.new do
          issue.assign_users(@repository.authenticated_user.username)
        end
      end
    end
  end
end
