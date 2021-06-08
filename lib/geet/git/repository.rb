# frozen_string_literal: true

require_relative '../utils/git_client'

module Geet
  module Git
    # This class represents, for convenience, both the local and the remote repository, but the
    # remote code is separated in each provider module.
    class Repository
      LOCAL_ACTION_ON_UPSTREAM_REPOSITORY_MESSAGE = <<~STR
        The action will be performed on a fork, but an upstream repository has been found!
      STR

      ACTION_ON_PROTECTED_REPOSITORY_MESSAGE = <<~STR
        This action will be performed on a protected repository!
      STR

      DEFAULT_GIT_CLIENT = Geet::Utils::GitClient.new

      # warnings:               disable all the warnings.
      # protected_repositories: warn when creating an issue/pr on this repositories (entry format:
      #                         `owner/repo`).
      #
      def initialize(upstream: false, git_client: DEFAULT_GIT_CLIENT, warnings: true, protected_repositories: [])
        @upstream = upstream
        @git_client = git_client
        @api_token = extract_env_api_token
        @warnings = warnings
        @protected_repositories = protected_repositories
      end

      # REMOTE FUNCTIONALITIES (REPOSITORY)

      def collaborators
        attempt_provider_call(:User, :list_collaborators, api_interface)
      end

      def labels
        attempt_provider_call(:Label, :list, api_interface)
      end

      def create_issue(title, description)
        confirm(LOCAL_ACTION_ON_UPSTREAM_REPOSITORY_MESSAGE) if local_action_on_upstream_repository? && @warnings
        confirm(ACTION_ON_PROTECTED_REPOSITORY_MESSAGE) if action_on_protected_repository? && @warnings

        attempt_provider_call(:Issue, :create, title, description, api_interface)
      end

      def create_label(name, color)
        attempt_provider_call(:Label, :create, name, color, api_interface)
      end

      def delete_branch(name)
        attempt_provider_call(:Branch, :delete, name, api_interface)
      end

      def issues(assignee: nil, milestone: nil)
        attempt_provider_call(:Issue, :list, api_interface, assignee: assignee, milestone: milestone)
      end

      def create_milestone(title)
        attempt_provider_call(:Milestone, :create, title, api_interface)
      end

      def milestone(number)
        attempt_provider_call(:Milestone, :find, number, api_interface)
      end

      def milestones
        attempt_provider_call(:Milestone, :list, api_interface)
      end

      def close_milestone(number)
        attempt_provider_call(:Milestone, :close, number, api_interface)
      end

      def create_pr(title, description, head, base)
        confirm(LOCAL_ACTION_ON_UPSTREAM_REPOSITORY_MESSAGE) if local_action_on_upstream_repository? && @warnings
        confirm(ACTION_ON_PROTECTED_REPOSITORY_MESSAGE) if action_on_protected_repository? && @warnings

        attempt_provider_call(:PR, :create, title, description, head, api_interface, base)
      end

      def prs(owner: nil, head: nil, milestone: nil)
        attempt_provider_call(:PR, :list, api_interface, owner: owner, head: head, milestone: milestone)
      end

      # Returns the RemoteRepository instance.
      #
      def remote
        attempt_provider_call(:RemoteRepository, :find, api_interface)
      end

      # REMOTE FUNCTIONALITIES (ACCOUNT)

      def authenticated_user
        attempt_provider_call(:User, :authenticated, api_interface)
      end

      # OTHER/CONVENIENCE FUNCTIONALITIES

      def upstream?
        @upstream
      end

      private

      # PROVIDER

      def extract_env_api_token
        env_variable_name = "#{provider_name.upcase}_API_TOKEN"

        ENV[env_variable_name] || raise("#{env_variable_name} not set!")
      end

      # Attempt to find the provider class and send the specified method, returning a friendly
      # error (functionality X [Y] is missing) when a class/method is missing.
      def attempt_provider_call(class_name, meth, *args)
        module_name = provider_name.capitalize

        require_provider_modules

        full_class_name = "Geet::#{module_name}::#{class_name}"

        if Kernel.const_defined?(full_class_name)
          klass = Kernel.const_get(full_class_name)

          if !klass.respond_to?(meth)
            raise "The functionality invoked (#{class_name}.#{meth}) is not currently supported!"
          end

          # Can't use ruby2_keywords, because the method definitions use named keyword arguments.
          #
          kwargs = args.last.is_a?(Hash) ? args.pop : {}

          klass.send(meth, *args, **kwargs)
        else
          raise "The class referenced (#{full_class_name}) is not currently supported!"
        end
      end

      def require_provider_modules
        files_pattern = "#{__dir__}/../#{provider_name}/*.rb"

        Dir[files_pattern].each { |filename| require filename }
      end

      # WARNINGS

      def confirm(message)
        full_message = "WARNING! #{message.strip}\nPress Enter to continue, or Ctrl+C to exit now."
        print full_message
        gets
      end

      def action_on_protected_repository?
        path = @git_client.path(upstream: @upstream)
        @protected_repositories.include?(path)
      end

      def local_action_on_upstream_repository?
        @git_client.remote_defined?('upstream') && !@upstream
      end

      # OTHER HELPERS

      def api_interface
        path = @git_client.path(upstream: @upstream)
        attempt_provider_call(:ApiInterface, :new, @api_token, repo_path: path, upstream: @upstream)
      end

      # Bare downcase provider name, eg. `github`
      #
      def provider_name
        @git_client.provider_domain[/(.*)\.\w+/, 1]
      end
    end
  end
end
