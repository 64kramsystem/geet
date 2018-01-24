# frozen_string_literal: true

require 'shellwords'
require_relative '../utils/git_client'

module Geet
  module Git
    # This class represents, for convenience, both the local and the remote repository, but the
    # remote code is separated in each provider module.
    class Repository
      CONFIRM_ACTION_TEXT = <<~STR
        WARNING! The action will be performed on a fork, but an upstream repository has been found!
        Press Enter to continue, or Ctrl+C to exit now.
      STR

      DEFAULT_GIT_CLIENT = Geet::Utils::GitClient.new

      def initialize(upstream: false, git_client: DEFAULT_GIT_CLIENT)
        @upstream = upstream
        @git_client = git_client
        @api_token = extract_env_api_token
      end

      # REMOTE FUNCTIONALITIES (REPOSITORY)

      def collaborators
        attempt_provider_call(:Collaborator, :list, api_interface)
      end

      def labels
        attempt_provider_call(:Label, :list, api_interface)
      end

      def create_gist(filename, content, description: nil, publik: false)
        attempt_provider_call(:Gist, :create, filename, content, api_interface, description: description, publik: publik)
      end

      def create_issue(title, description)
        ask_confirm_action if local_action_with_upstream_repository?
        attempt_provider_call(:Issue, :create, title, description, api_interface)
      end

      def create_label(name, color)
        attempt_provider_call(:Label, :create, name, color, api_interface)
      end

      def delete_branch(name)
        attempt_provider_call(:Branch, :delete, name, api_interface)
      end

      def abstract_issues(milestone: nil)
        attempt_provider_call(:AbstractIssue, :list, api_interface, milestone: milestone)
      end

      def issues(assignee: nil)
        attempt_provider_call(:Issue, :list, api_interface, assignee: assignee)
      end

      def milestone(number)
        attempt_provider_call(:Milestone, :find, number, api_interface)
      end

      def milestones
        attempt_provider_call(:Milestone, :list, api_interface)
      end

      def create_pr(title, description, head)
        ask_confirm_action if local_action_with_upstream_repository?
        attempt_provider_call(:PR, :create, title, description, head, api_interface)
      end

      def prs(head: nil)
        attempt_provider_call(:PR, :list, api_interface, head: head)
      end

      # REMOTE FUNCTIONALITIES (ACCOUNT)

      def authenticated_user
        attempt_provider_call(:Account, :new, api_interface).authenticated_user
      end

      # OTHER/CONVENIENCE FUNCTIONALITIES

      def current_branch
        @git_client.current_branch
      end

      def upstream?
        @upstream
      end

      private

      # PROVIDER

      def extract_env_api_token
        provider_name = @git_client.provider_domain[/(.*)\.\w+/, 1]
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
            raise "The functionality invoked (#{class_name} #{meth}) is not currently supported!"
          end

          klass.send(meth, *args)
        else
          raise "The functionality (#{class_name}) invoked is not currently supported!"
        end
      end

      def require_provider_modules
        files_pattern = "#{__dir__}/../#{provider_name}/*.rb"

        Dir[files_pattern].each { |filename| require filename }
      end

      # OTHER HELPERS

      def api_interface
        path = @git_client.path(upstream: @upstream)
        attempt_provider_call(:ApiInterface, :new, @api_token, repo_path: path, upstream: @upstream)
      end

      def ask_confirm_action
        print CONFIRM_ACTION_TEXT.rstrip
        gets
      end

      def local_action_with_upstream_repository?
        @git_client.remote_defined?('upstream') && !@upstream
      end

      # Bare downcase provider name, eg. `github`
      #
      def provider_name
        @git_client.provider_domain[/(.*)\.\w+/, 1]
      end
    end
  end
end
