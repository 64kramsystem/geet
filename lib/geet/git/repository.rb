# frozen_string_literal: true

require 'forwardable'

Dir[File.join(__dir__, '../**/remote_repository.rb')].each { |repository_file| require repository_file }
Dir[File.join(__dir__, '../**/account.rb')].each { |account_file| require account_file }
Dir[File.join(__dir__, '../**/api_helper.rb')].each { |helper_file| require helper_file }
Dir[File.join(__dir__, '../services/*.rb')].each { |helper_file| require helper_file }

module Geet
  module Git
    # This class represents, for convenience, both the local and the remote repository, but the
    # remote code is separated in each provider module.
    class Repository
      extend Forwardable

      def_delegators :@remote_repository, :collaborators, :labels
      def_delegators :@remote_repository, :create_gist
      def_delegators :@remote_repository, :create_issue, :list_issues
      def_delegators :@remote_repository, :create_pr, :list_prs
      def_delegators :@account, :authenticated_user

      DOMAIN_PROVIDERS_MAPPING = {
        'github.com' => Geet::GitHub
      }.freeze

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

      def initialize(api_token, upstream: false)
        the_provider_domain = provider_domain
        provider_module = DOMAIN_PROVIDERS_MAPPING[the_provider_domain] || raise("Provider not supported for domain: #{provider_domain}")

        api_helper = provider_module::ApiHelper.new(api_token, user, path(upstream: upstream), upstream)

        @remote_repository = provider_module::RemoteRepository.new(self, api_helper)
        @account = provider_module::Account.new(api_helper)
      end

      # METADATA

      def user
        `git config --get user.email`.strip
      end

      def provider_domain
        # We assume that it's not possible to have origin and upstream on different providers.
        #
        remote_url = remote(ORIGIN_NAME)

        remote_url[REMOTE_ORIGIN_REGEX, 1] || remote_url[REMOTE_ORIGIN_REGEX, 2]
      end

      def path(upstream: false)
        remote_name = upstream ? UPSTREAM_NAME : ORIGIN_NAME

        remote(remote_name)[REMOTE_ORIGIN_REGEX, 3]
      end

      # DATA

      def current_branch
        branch = `git rev-parse --abbrev-ref HEAD`.strip

        raise "Couldn't find current branch" if branch == 'HEAD'

        branch
      end

      # OTHER

      private

      # The result is in the format `git@github.com:saveriomiroddi/geet.git`
      #
      def remote(name)
        remote_url = `git ls-remote --get-url #{name}`.strip

        if remote_url == name
          raise "Remote #{name.inspect} not found!"
        elsif remote_url !~ REMOTE_ORIGIN_REGEX
          raise "Unexpected remote reference format: #{remote_url.inspect}"
        end

        remote_url
      end
    end
  end
end
