# frozen_string_literal: true
# typed: strict

module Geet
  module Gitlab
    class User
      extend T::Sig

      sig { returns(Integer) }
      attr_reader :id

      sig { returns(String) }
      attr_reader :username

      sig {
        params(
          id: Integer,
          username: String,
          api_interface: ApiInterface
        ).void
      }
      def initialize(id, username, api_interface)
        @id = id
        @username = username
        @api_interface = api_interface
      end

      # Returns an array of User instances
      #
      sig {
        params(
          api_interface: ApiInterface
        ).returns(T::Array[User])
      }
      def self.list_collaborators(api_interface)
        api_path = "projects/#{api_interface.path_with_namespace(encoded: true)}/members"

        response = T.cast(
          api_interface.send_request(api_path, multipage: true),
          T::Array[T::Hash[String, T.untyped]]
        )

        response.map do |user_entry|
          id = T.cast(user_entry.fetch("id"), Integer)
          username = T.cast(user_entry.fetch("username"), String)

          new(id, username, api_interface)
        end
      end
    end # User
  end # Gitlab
end # Geet
