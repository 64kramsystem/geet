# frozen_string_literal: true
# typed: strict

module Geet
  module Github
    class User
      extend T::Sig
      include Geet::Shared::RepoPermissions

      sig { returns(String) }
      attr_reader :username

      sig {
        params(
          username: String,
          api_interface: Geet::Github::ApiInterface
        ).void
      }
      def initialize(username, api_interface)
        @username = username
        @api_interface = api_interface
      end

      # See #repo_permission.
      #
      sig {
        params(
          permission: String
        ).returns(T::Boolean)
      }
      def has_permission?(permission)
        user_permission = self.class.repo_permission(@api_interface)

        permission_greater_or_equal_to?(user_permission, permission)
      end

      # See https://developer.github.com/v3/repos/collaborators/#check-if-a-user-is-a-collaborator
      #
      sig { returns(T::Boolean) }
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
      sig {
        params(
          api_interface: Geet::Github::ApiInterface
        ).returns(Geet::Github::User)
      }
      def self.authenticated(api_interface)
        api_path = '/user'

        response = T.cast(api_interface.send_request(api_path), T::Hash[String, T.untyped])

        login = T.cast(response.fetch('login'), String)

        new(login, api_interface)
      end

      sig {
        params(
          api_interface: Geet::Github::ApiInterface
        ).returns(T::Array[Geet::Github::User])
      }
      def self.list_collaborators(api_interface)
        api_path = 'collaborators'
        response = T.cast(api_interface.send_request(api_path, multipage: true), T::Array[T::Hash[String, T.untyped]])

        response.map do |user_entry|
          login = T.cast(user_entry.fetch('login'), String)
          new(login, api_interface)
        end
      end

      # See https://developer.github.com/v3/repos/collaborators/#review-a-users-permission-level
      #
      sig {
        params(
          api_interface: Geet::Github::ApiInterface
        ).returns(String)
      }
      def self.repo_permission(api_interface)
        username = authenticated(api_interface).username
        api_path = "collaborators/#{username}/permission"

        response = T.cast(api_interface.send_request(api_path), T::Hash[String, T.untyped])

        permission = T.cast(response.fetch('permission'), String)

        check_permission!(permission)

        permission
      end

      class << self
        extend T::Sig

        private

        # Future-proofing.
        #
        sig { params(permission: String).void }
        def check_permission!(permission)
          raise "Unexpected permission #{permission.inspect}!" if !Geet::Shared::RepoPermissions::ALL_PERMISSIONS.include?(permission)
        end
      end
    end
  end
end
