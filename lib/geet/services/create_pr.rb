# frozen_string_literal: true

require_relative 'abstract_create_issue'
require_relative '../shared/repo_permissions'
require_relative '../shared/selection'

module Geet
  module Services
    class CreatePr < AbstractCreateIssue
      include Geet::Shared::RepoPermissions
      include Geet::Shared::Selection

      DEFAULT_GIT_CLIENT = Geet::Utils::GitClient.new

      def initialize(repository, out: $stdout, git_client: DEFAULT_GIT_CLIENT)
        super(repository)
        @git_client = git_client
        @out = out
      end

      # options:
      #   :labels
      #   :reviewers
      #   :no_open_pr
      #
      def execute(
        title, description, labels: nil, milestone: nil, reviewers: nil,
        base: nil, draft: false, no_open_pr: nil, automated_mode: false, **
      )
        ensure_clean_tree if automated_mode

        # See CreateIssue#execute for notes about performance.
        user_has_write_permissions = @repository.authenticated_user.is_collaborator? &&
                                     @repository.authenticated_user.has_permission?(PERMISSION_WRITE)

        if user_has_write_permissions
          selected_labels, selected_milestone, selected_reviewers = find_and_select_attributes(labels, milestone, reviewers)
        end

        sync_with_upstream_branch if automated_mode

        pr = create_pr(title, description, base: base, draft: draft)

        if user_has_write_permissions
          edit_pr(pr, selected_labels, selected_milestone, selected_reviewers)
        end

        if no_open_pr
          @out.puts "PR address: #{pr.link}"
        else
          open_file_with_default_application(pr.link)
        end

        pr
      rescue => error
        save_summary(title, description) if title
        raise
      end

      private

      # Internal actions

      def ensure_clean_tree
        raise 'The working tree is not clean!' if !@git_client.working_tree_clean?
      end

      def find_and_select_attributes(labels, milestone, reviewers)
        selection_manager = Geet::Utils::AttributesSelectionManager.new(@repository, out: @out)

        selection_manager.add_attribute(:labels, 'label', labels, SELECTION_MULTIPLE, name_method: :name) if labels
        selection_manager.add_attribute(:milestones, 'milestone', milestone, SELECTION_SINGLE, name_method: :title) if milestone

        if reviewers
          selection_manager.add_attribute(:collaborators, 'reviewer', reviewers, SELECTION_MULTIPLE, name_method: :username) do |all_reviewers|
            authenticated_user = @repository.authenticated_user
            all_reviewers.delete_if { |reviewer| reviewer.username == authenticated_user.username }
          end
        end

        selection_manager.select_attributes
      end

      def sync_with_upstream_branch
        if @git_client.upstream_branch
          @out.puts "Pushing to upstream branch..."

          @git_client.push
        else
          upstream_branch = @git_client.current_branch

          @out.puts "Creating upstream branch #{upstream_branch.inspect}..."

          @git_client.push(upstream_branch: upstream_branch)
        end
      end

      def create_pr(title, description, base:, draft:)
        @out.puts 'Creating PR...'

        base ||= @git_client.main_branch

        @repository.create_pr(title, description, @git_client.current_branch, base, draft)
      end

      def edit_pr(pr, labels, milestone, reviewers)
        assign_user_thread = assign_authenticated_user(pr)

        # labels/reviewers can be nil (parameter not passed) or empty array (parameter passed, but
        # nothing selected)
        add_labels_thread = add_labels(pr, labels) if labels && !labels.empty?
        set_milestone_thread = set_milestone(pr, milestone) if milestone
        request_review_thread = request_review(pr, reviewers) if reviewers && !reviewers.empty?

        assign_user_thread.join
        add_labels_thread&.join
        set_milestone_thread&.join
        request_review_thread&.join
      end

      def assign_authenticated_user(pr)
        @out.puts 'Assigning authenticated user...'

        Thread.new do
          pr.assign_users(@repository.authenticated_user.username)
        end
      end

      def add_labels(pr, selected_labels)
        labels_list = selected_labels.map(&:name).join(', ')

        @out.puts "Adding labels #{labels_list}..."

        Thread.new do
          pr.add_labels(selected_labels.map(&:name))
        end
      end

      def set_milestone(pr, milestone)
        @out.puts "Setting milestone #{milestone.title}..."

        Thread.new do
          pr.edit(milestone: milestone.number)
        end
      end

      def request_review(pr, reviewers)
        reviewer_usernames = reviewers.map(&:username)

        @out.puts "Requesting review from #{reviewer_usernames.join(', ')}..."

        Thread.new do
          pr.request_review(reviewer_usernames)
        end
      end
    end
  end
end
