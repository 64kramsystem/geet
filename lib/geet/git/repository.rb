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
      def_delegators :@remote_repository, :create_issue, :create_pr
      def_delegators :@account, :authenticated_user

      DOMAIN_PROVIDERS_MAPPING = {
        'github.com' => Geet::GitHub
      }.freeze

      # For simplicity, we match any character except the ones the separators.
      REMOTE_ORIGIN_REGEX = %r{\Agit@([^:]+):([^/]+)/(.*?)(\.git)?\Z}

      def initialize(api_token)
        the_provider_domain = provider_domain
        provider_module = DOMAIN_PROVIDERS_MAPPING[the_provider_domain] || raise("Provider not supported for domain: #{provider_domain}")

        api_helper = provider_module::ApiHelper.new(api_token, user, owner, repo)

        @remote_repository = provider_module::RemoteRepository.new(self, api_helper)
        @account = provider_module::Account.new(api_helper)
      end

      # METADATA

      def user
        `git config --get user.email`.strip
      end

      def provider_domain
        remote_origin[REMOTE_ORIGIN_REGEX, 1]
      end

      def owner
        remote_origin[REMOTE_ORIGIN_REGEX, 2]
      end

      def repo
        remote_origin[REMOTE_ORIGIN_REGEX, 3]
      end

      # DATA

      def current_head
        `git rev-parse --abbrev-ref HEAD`.strip
      end

      # OTHER

      private

      # The result is in the format `git@github.com:saveriomiroddi/geet.git`
      #
      def remote_origin
        origin = `git ls-remote --get-url origin`.strip

        if origin !~ REMOTE_ORIGIN_REGEX
          raise("Unexpected remote reference format: #{origin.inspect}")
        end

        origin
      end
    end
  end
end
