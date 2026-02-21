# frozen_string_literal: true
# typed: strict

module Geet
  module Git
    # This class represents, for convenience, both the local and the remote repository, but the
    # remote code is separated in each provider module.
    class Repository
      extend T::Sig

      LOCAL_ACTION_ON_UPSTREAM_REPOSITORY_MESSAGE = <<~STR
        The action will be performed on a fork, but an upstream repository has been found!
      STR

      ACTION_ON_PROTECTED_REPOSITORY_MESSAGE = <<~STR
        This action will be performed on a protected repository!
      STR

      DEFAULT_GIT_CLIENT = Geet::Utils::GitClient.new

      sig {
        params(
          upstream: T::Boolean,
          git_client: Utils::GitClient,
          warnings: T::Boolean,                          # disable all the warnings
          protected_repositories: T::Array[String]       # warn when creating an issue/pr on these repos (format: `owner/repo`)
        )
        .void
      }
      def initialize(upstream: false, git_client: DEFAULT_GIT_CLIENT, warnings: true, protected_repositories: [])
        @upstream = upstream
        @git_client = git_client
        @api_token = T.let(extract_env_api_token, String)
        @warnings = warnings
        @protected_repositories = protected_repositories
      end

      # REMOTE FUNCTIONALITIES (REPOSITORY)

      sig { returns(T::Array[Github::User]) }
      def collaborators
        Github::User.list_collaborators(api_interface)
      end

      sig { returns(T::Array[Github::Label]) }
      def labels
        Github::Label.list(api_interface)
      end

      sig {
        params(
          title: String,
          description: String
        )
        .returns(Github::Issue)
      }
      def create_issue(title, description)
        confirm(LOCAL_ACTION_ON_UPSTREAM_REPOSITORY_MESSAGE) if local_action_on_upstream_repository? && @warnings
        confirm(ACTION_ON_PROTECTED_REPOSITORY_MESSAGE) if action_on_protected_repository? && @warnings

        Github::Issue.create(title, description, api_interface)
      end

      sig {
        params(
          name: String,
          color: String
        )
        .returns(Github::Label)
      }
      def create_label(name, color)
        Github::Label.create(name, color, api_interface)
      end

      sig { params(name: String).void }
      def delete_branch(name)
        Github::Branch.delete(name, api_interface)
      end

      sig {
        params(
          assignee: T.nilable(Github::User),
          milestone: T.nilable(Github::Milestone)
        )
        .returns(T::Array[Github::AbstractIssue])
      }
      def issues(assignee: nil, milestone: nil)
        Github::Issue.list(api_interface, assignee:, milestone:)
      end

      sig {
        params(
          title: String
        )
        .returns(Github::Milestone)
      }
      def create_milestone(title)
        Github::Milestone.create(title, api_interface)
      end

      sig { returns(T::Array[Github::Milestone]) }
      def milestones
        Github::Milestone.list(api_interface)
      end

      sig { params(number: Integer).void }
      def close_milestone(number)
        Github::Milestone.close(number, api_interface)
      end

      sig {
        params(
          title: String,
          description: String,
          head: String,                                    # source branch
          base: String,                                    # target branch
          draft: T::Boolean
        )
        .returns(Github::PR)
      }
      def create_pr(title, description, head, base, draft)
        confirm(LOCAL_ACTION_ON_UPSTREAM_REPOSITORY_MESSAGE) if local_action_on_upstream_repository? && @warnings
        confirm(ACTION_ON_PROTECTED_REPOSITORY_MESSAGE) if action_on_protected_repository? && @warnings

        Github::PR.create(title, description, head, api_interface, base, draft: draft)
      end

      sig {
        params(
          owner: T.nilable(String),                                      # filter by repository owner
          head: T.nilable(String),                                       # filter by source branch
          milestone: T.nilable(Github::Milestone)
        )
        .returns(T::Array[Github::PR])
      }
      def prs(owner: nil, head: nil, milestone: nil)
        Github::PR.list(api_interface, owner:, head:, milestone:)
      end

      # Returns the RemoteRepository instance.
      #
      sig { returns(Github::RemoteRepository) }
      def remote
        Github::RemoteRepository.find(api_interface)
      end

      # REMOTE FUNCTIONALITIES (ACCOUNT)

      sig { returns(Github::User) }
      def authenticated_user
        Github::User.authenticated(api_interface)
      end

      # OTHER/CONVENIENCE FUNCTIONALITIES

      sig { returns(T::Boolean) }
      def upstream?
        @upstream
      end

      # For cases where it's necessary to work on the downstream repo.
      #
      sig { returns(Git::Repository) }
      def downstream
        raise "downstream() is not available on not-upstream repositories!" if !upstream?

        Git::Repository.new(upstream: false, protected_repositories: @protected_repositories)
      end

      private

      # WARNINGS

      sig { params(message: String).void }
      def confirm(message)
        full_message = "WARNING! #{message.strip}\nPress Enter to continue, or Ctrl+C to exit now."
        print full_message
        gets
      end

      sig { returns(T::Boolean) }
      def action_on_protected_repository?
        path = @git_client.path(upstream: @upstream)
        @protected_repositories.include?(path)
      end

      sig { returns(T::Boolean) }
      def local_action_on_upstream_repository?
        @git_client.remote_defined?(Utils::GitClient::UPSTREAM_NAME) && !@upstream
      end

      # OTHER HELPERS

      sig { returns(Github::ApiInterface) }
      def api_interface
        path = @git_client.path(upstream: @upstream)
        Github::ApiInterface.new(@api_token, repo_path: path, upstream: @upstream)
      end

      sig { returns(String) }
      def extract_env_api_token
        ENV["GITHUB_API_TOKEN"] || raise("GITHUB_API_TOKEN not set!")
      end
    end
  end
end
