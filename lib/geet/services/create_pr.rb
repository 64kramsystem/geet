# frozen_string_literal: true

require 'tmpdir'
require_relative '../helpers/os_helper.rb'
require_relative '../helpers/selection_helper.rb'

module Geet
  module Services
    class CreatePr
      include Geet::Helpers::OsHelper
      include Geet::Helpers::SelectionHelper

      DEFAULT_GIT_CLIENT = Geet::Utils::GitClient.new

      SUMMARY_BACKUP_FILENAME = File.join(Dir.tmpdir, 'last_geet_edited_summary.md')

      def initialize(repository, git_client: DEFAULT_GIT_CLIENT)
        @repository = repository
        @git_client = git_client
      end

      # options:
      #   :labels
      #   :reviewers
      #   :no_open_pr
      #
      def execute(
        title, description, labels: nil, milestone: nil, reviewers: nil,
        no_open_pr: nil, automated_mode: false, output: $stdout, **
      )
        ensure_clean_tree if automated_mode

        all_labels_thread = find_attribute_entries(:labels, output) if labels
        all_milestones_thread = find_attribute_entries(:milestones, output) if milestone
        all_collaborators_thread = find_attribute_entries(:collaborators, output) if reviewers

        selected_labels = select_entries('label', all_labels_thread.value, labels, :name) if labels
        selected_milestone = select_entry('milestone', all_milestones_thread.value, milestone, :title) if milestone
        selected_reviewers = select_entries('reviewer', all_collaborators_thread.value, reviewers, nil) if reviewers

        sync_with_upstream_branch(output) if automated_mode

        pr = create_pr(title, description, output)

        edit_pr(pr, selected_labels, selected_milestone, selected_reviewers, output)

        if no_open_pr
          output.puts "PR address: #{pr.link}"
        else
          open_file_with_default_application(pr.link)
        end

        pr
      rescue => error
        save_summary(title, description, output) if title
        raise
      end

      private

      # Internal actions

      def ensure_clean_tree
        raise 'The working tree is not clean!' if !@git_client.working_tree_clean?
      end

      def find_attribute_entries(repository_call, output)
        output.puts "Finding #{repository_call}..."

        Thread.new do
          entries = @repository.send(repository_call)

          raise "No #{repository_call} found!" if entries.empty?

          entries
        end
      end

      def sync_with_upstream_branch(output)
        if @git_client.upstream_branch
          output.puts "Pushing to upstream branch..."

          @git_client.push
        else
          upstream_branch = @git_client.current_branch

          output.puts "Creating upstream branch #{upstream_branch.inspect}..."

          @git_client.push(upstream_branch: upstream_branch)
        end
      end

      def create_pr(title, description, output)
        output.puts 'Creating PR...'

        @repository.create_pr(title, description, @git_client.current_branch)
      end

      def edit_pr(pr, labels, milestone, reviewers, output)
        assign_user_thread = assign_authenticated_user(pr, output)

        # labels/reviewers can be nil (parameter not passed) or empty array (parameter passed, but
        # nothing selected)
        add_labels_thread = add_labels(pr, labels, output) if labels && !labels.empty?
        set_milestone_thread = set_milestone(pr, milestone, output) if milestone
        request_review_thread = request_review(pr, reviewers, output) if reviewers && !reviewers.empty?

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

      def save_summary(title, description, output)
        summary = "#{title}\n\n#{description}".strip + "\n"

        IO.write(SUMMARY_BACKUP_FILENAME, summary)

        output.puts "Error! Saved summary to #{SUMMARY_BACKUP_FILENAME}"
      end
    end
  end
end
