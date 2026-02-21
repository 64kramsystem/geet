# frozen_string_literal: true
# typed: strict

require "io/console" # stdlib

module Geet
  module Services
    class CreatePr
      extend T::Sig

      include Geet::Helpers::OsHelper
      include Geet::Shared::RepoPermissions
      include Geet::Shared::Selection

      DEFAULT_GIT_CLIENT = Geet::Utils::GitClient.new

      sig {
        params(
          repository: Git::Repository,
          out: T.any(IO, StringIO),
          git_client: Utils::GitClient
        ).void
      }
      def initialize(repository, out: $stdout, git_client: DEFAULT_GIT_CLIENT)
        @repository = repository
        @git_client = git_client
        @out = out
      end

      sig {
        params(
          title: String,
          description: String,
          labels: T.nilable(String),
          milestone: T.nilable(String),
          reviewers: T.nilable(String),
          base: T.nilable(String),
          draft: T::Boolean,
          open_browser: T::Boolean,
          automerge: T::Boolean,
          _: T.untyped,
        ).returns(Github::PR)
      }
      def execute(
        title, description, labels: nil, milestone: nil, reviewers: nil,
        base: nil, draft: false, open_browser: false, automerge: false,
        **_
      )
        ensure_clean_tree

        if @repository.upstream? && !@git_client.remote_defined?(Utils::GitClient::UPSTREAM_NAME)
          @out.puts "Upstream not found; adding it to the repository remotes..."

          AddUpstreamRepo.new(@repository.downstream, out: @out, git_client: @git_client).execute
        end

        # See CreateIssue#execute for notes about performance.
        user_has_write_permissions = @repository.authenticated_user.is_collaborator? &&
                                     @repository.authenticated_user.has_permission?(PERMISSION_WRITE)

        if user_has_write_permissions
          selected_labels, selected_milestone, selected_reviewers = find_and_select_attributes(labels, milestone, reviewers)
        end

        sync_with_remote_branch

        pr = create_pr(title, description, base:, draft:)

        if user_has_write_permissions
          edit_pr(pr, selected_labels, selected_milestone, selected_reviewers)
        end

        enable_automerge(pr) if automerge

        if open_browser
          open_file_with_default_application(pr.link)
        else
          @out.puts "PR address: #{pr.link}"
        end

        pr
      end

      private

      # Internal actions

      sig { void }
      def ensure_clean_tree
        raise "The working tree is not clean!" if !@git_client.working_tree_clean?
      end

      sig {
        params(
          labels: T.nilable(String),
          milestone: T.nilable(String),
          reviewers: T.nilable(String)
        ).returns([
          T.nilable(T::Array[Github::Label]),
          T.nilable(Github::Milestone),
          T.nilable(T::Array[Github::User]),
        ])
      }
      def find_and_select_attributes(labels, milestone, reviewers)
        selection_manager = Geet::Utils::AttributesSelectionManager.new(@repository, out: @out)

        selection_manager.add_attribute(:labels, "label", labels, SELECTION_MULTIPLE, name_method: :name) if labels
        selection_manager.add_attribute(:milestones, "milestone", milestone, SELECTION_SINGLE, name_method: :title) if milestone

        if reviewers
          selection_manager.add_attribute(:collaborators, "reviewer", reviewers, SELECTION_MULTIPLE, name_method: :username) do |all_reviewers|
            authenticated_user = @repository.authenticated_user
            reviewers_typed = T.cast(all_reviewers, T::Array[Github::User])
            reviewers_typed.delete_if { |reviewer| reviewer.username == authenticated_user.username }
          end
        end

        selected_attributes = selection_manager.select_attributes

        selected_labels = T.cast(selected_attributes.shift, T.nilable(T::Array[Github::Label])) if labels
        selected_milestone = T.cast(selected_attributes.shift, T.nilable(Github::Milestone)) if milestone
        selected_reviewers = T.cast(selected_attributes.shift, T.nilable(T::Array[Github::User])) if reviewers

        [selected_labels, selected_milestone, selected_reviewers]
      end

      sig { void }
      def sync_with_remote_branch
        # Fetching doesn't have a real world case when there isn't a remote branch. It's also not generally
        # useful when there is a remote branch, however, since a force push is an option, it's important
        # to be 100% sure of the current diff.

        if @git_client.remote_branch
          @out.puts "Pushing to remote branch..."

          @git_client.fetch

          input = T.let("", String)

          if !@git_client.remote_branch_diff_commits.empty?
            while true
              @out.print "The local and remote branches differ! Force push (Y/D/Q*)?"
              input = $stdin.getch
              @out.puts

              case input.downcase
              when "y"
                @git_client.push(force: true)
                break
              when "d"
                @out.puts "# DIFF: ########################################################################"
                @out.puts @git_client.remote_branch_diff
                @out.puts "################################################################################"
              when "q"
                exit(1)
              end
            end
          else
            @git_client.push
          end
        else
          remote_branch = @git_client.current_branch

          @out.puts "Creating remote branch #{remote_branch.inspect}..."

          begin
            @git_client.push(remote_branch: remote_branch)
          rescue
            # A case where this helps is if a push hook fails.
            #
            @out.print "Error while pushing; retry (Y/N*)?"
            input = $stdin.getch
            @out.puts

            case input.downcase.rstrip
            when "n", ""
              # exit the cycle
            else
              retry
            end
          end
        end
      end

      sig {
        params(
          title: String,
          description: String,
          base: T.nilable(String),
          draft: T::Boolean
        ).returns(Github::PR)
      }
      def create_pr(title, description, base:, draft:)
        @out.puts "Creating PR..."

        base ||= @git_client.main_branch

        @repository.create_pr(title, description, @git_client.current_branch, base, draft)
      end

      sig {
        params(
          pr: Github::PR,
          labels: T.nilable(T::Array[Github::Label]),
          milestone: T.nilable(Github::Milestone),
          reviewers: T.nilable(T::Array[Github::User])
        ).void
      }
      def edit_pr(pr, labels, milestone, reviewers)
        # labels/reviewers can be nil (parameter not passed) or empty array (parameter passed, but
        # nothing selected)
        add_labels_thread = add_labels(pr, labels) if labels && !labels.empty?
        set_milestone_thread = set_milestone(pr, milestone) if milestone
        request_review_thread = request_review(pr, reviewers) if reviewers && !reviewers.empty?

        add_labels_thread&.join
        set_milestone_thread&.join
        request_review_thread&.join
      end

      sig {
        params(
          pr: Github::PR,
          selected_labels: T::Array[Github::Label]
        ).returns(Thread)
      }
      def add_labels(pr, selected_labels)
        labels_list = selected_labels.map(&:name).join(", ")

        @out.puts "Adding labels #{labels_list}..."

        Thread.new do
          pr.add_labels(selected_labels.map(&:name))
        end
      end

      sig {
        params(
          pr: Github::PR,
          milestone: Github::Milestone
        ).returns(Thread)
      }
      def set_milestone(pr, milestone)
        @out.puts "Setting milestone #{milestone.title}..."

        Thread.new do
          pr.edit(milestone: milestone.number)
        end
      end

      sig {
        params(
          pr: Github::PR,
          reviewers: T::Array[Github::User]
        ).returns(Thread)
      }
      def request_review(pr, reviewers)
        reviewer_usernames = reviewers.map(&:username)

        @out.puts "Requesting review from #{reviewer_usernames.join(', ')}..."

        Thread.new do
          pr.request_review(reviewer_usernames)
        end
      end

      sig {
        params(
          pr: Github::PR
        ).void
      }
      def enable_automerge(pr)
        if !pr.respond_to?(:enable_automerge)
          raise "Automerge is not supported for this repository provider"
        elsif !pr.respond_to?(:node_id) || pr.node_id.nil?
          raise "Automerge requires node_id from the API (not available in the response)"
        end

        @out.print "Enabling automerge... "

        begin
          merge_method = pr.enable_automerge
          @out.puts merge_method
        rescue Geet::Shared::HttpError => e
          @out.puts "", "WARNING: Could not enable automerge: #{e.message}"
        end
      end
    end
  end
end
