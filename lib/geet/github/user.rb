# frozen_string_literal: true

require_relative '../shared/repo_permissions'
require_relative '../shared/http_error'

module Geet
  module Github
    class User
      include Geet::Shared::RepoPermissions

      attr_reader :username

      def initialize(username, api_interface)
        @username = username
        @api_interface = api_interface
      end

      # See #repo_permission.
      #
      def has_permission?(permission)
        user_permission = self.class.repo_permission(@api_interface)

        permission_greater_or_equal_to?(user_permission, permission)
      end

      # See https://developer.github.com/v3/repos/collaborators/#check-if-a-user-is-a-collaborator
      #
      def is_collaborator?
        api_path = "collaborators/#{@username}"

        begin
          @api_interface.send_request(api_path)

          # 204: user is a collaborator.
          true
        rescue Geet::Shared::HttpError => error
          # 404: not a collaborator.
          # Although the documentation mentions only 404, 403 is a valid response as well; it seems
          # that 404 is given on private repositories, while 403 on public ones ("Must have push
          # access to view repository collaborators.").
          #
          (error.code == 404 || error.code == 403) ? false : raise
        end
      end

      # See https://developer.github.com/v3/users/#get-the-authenticated-user
      #
      def self.authenticated(api_interface)
        api_path = '/user'

        response = api_interface.send_request(api_path)

        new(response.fetch('login'), api_interface)
      end

      # Returns an array of User instances
      #
      def self.list_collaborators(api_interface)
        api_path = 'collaborators'
        response = api_interface.send_request(api_path, multipage: true)

        response.map { |user_entry| new(user_entry.fetch('login'), api_interface) }
      end

      # See https://developer.github.com/v3/repos/collaborators/#review-a-users-permission-level
      #
      def self.repo_permission(api_interface)
        username = authenticated(api_interface).username
        api_path = "collaborators/#{username}/permission"

        response = api_interface.send_request(api_path)

        permission = response.fetch('permission')

        check_permission!(permission)

        permission
      end

      class << self
        private

        # Future-proofing.
        #
        def check_permission!(permission)
          raise "Unexpected permission #{permission.inspect}!" if !self::ALL_PERMISSIONS.include?(permission)
        end
      end
    end
  end
end
