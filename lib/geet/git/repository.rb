# frozen_string_literal: true

require 'shellwords'

module Geet
  module Git
    # This class represents, for convenience, both the local and the remote repository, but the
    # remote code is separated in each provider module.
    class Repository
      # For simplicity, we match any character except the ones the separators.
      REMOTE_ORIGIN_REGEX = %r{
        \A
        (?:https://(.+?)/|git@(.+?):)
        ([^/]+/.*?)
        (?:\.git)?
        \Z
      }x

      ORIGIN_NAME   = 'origin'
      UPSTREAM_NAME = 'upstream'

      def initialize(upstream: false, location: nil)
        @upstream = upstream
        @location = location
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
        attempt_provider_call(:Issue, :create, title, description, api_interface)
      end

      def abstract_issues(milestone: nil)
        attempt_provider_call(:AbstractIssue, :list, api_interface, milestone: milestone)
      end

      def issues
        attempt_provider_call(:Issue, :list, api_interface)
      end

      def milestone(number)
        attempt_provider_call(:Milestone, :find, number, api_interface)
      end

      def milestones
        attempt_provider_call(:Milestone, :list, api_interface)
      end

      def create_pr(title, description, head)
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
        gitdir_option = "--git-dir #{@location.shellescape}/.git" if @location
        branch = `git #{gitdir_option} rev-parse --abbrev-ref HEAD`.strip

        raise "Couldn't find current branch" if branch == 'HEAD'

        branch
      end

      private

      # REPOSITORY METADATA

      # The result is in the format `git@github.com:donaldduck/geet.git`
      #
      def remote(name)
        gitdir_option = "--git-dir #{@location.shellescape}/.git" if @location
        remote_url = `git #{gitdir_option} ls-remote --get-url #{name}`.strip

        if remote_url == name
          raise "Remote #{name.inspect} not found!"
        elsif remote_url !~ REMOTE_ORIGIN_REGEX
          raise "Unexpected remote reference format: #{remote_url.inspect}"
        end

        remote_url
      end

      # PROVIDER

      def extract_env_api_token
        env_variable_name = "#{provider_domain[/(.*)\.\w+/, 1].upcase}_API_TOKEN"

        ENV[env_variable_name] || raise("#{env_variable_name} not set!")
      end

      def provider_domain
        # We assume that it's not possible to have origin and upstream on different providers.
        #
        remote_url = remote(ORIGIN_NAME)

        domain = remote_url[REMOTE_ORIGIN_REGEX, 1] || remote_url[REMOTE_ORIGIN_REGEX, 2]

        raise "Can't identify domain in the provider domain string: #{provider_domain}" if domain !~ /(.*)\.\w+/

        domain
      end

      # Attempt to find the provider class and send the specified method, returning a friendly
      # error (functionality X [Y] is missing) when a class/method is missing.
      def attempt_provider_call(class_name, meth, *args)
        module_name = provider_domain[/(.*)\.\w+/, 1].capitalize

        require_provider_modules

        full_class_name = "Geet::#{module_name}::#{class_name}"

        if Kernel.const_defined?(full_class_name)
          klass = Kernel.const_get(full_class_name)

          if ! klass.respond_to?(meth)
            raise "The functionality invoked (#{class_name} #{meth}) is not currently supported!"
          end

          klass.send(meth, *args)
        else
          raise "The functionality (#{class_name}) invoked is not currently supported!"
        end
      end

      def require_provider_modules
        provider_dirname = provider_domain[/(.*)\.\w+/, 1]
        files_pattern = "#{__dir__}/../#{provider_dirname}/*.rb"

        Dir[files_pattern].each { |filename| require filename }
      end

      # OTHER HELPERS

      def api_interface
        attempt_provider_call(:ApiInterface, :new, @api_token, path(upstream: @upstream), @upstream)
      end

      # Example: `donaldduck/geet`
      #
      def path(upstream: false)
        remote_name = upstream ? UPSTREAM_NAME : ORIGIN_NAME

        remote(remote_name)[REMOTE_ORIGIN_REGEX, 3]
      end
    end
  end
end
