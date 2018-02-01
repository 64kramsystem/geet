# frozen_string_literal: true

module Geet
  module Github
    class User
      attr_reader :username

      def initialize(username)
        @username = username
      end

      # See https://developer.github.com/v3/users/#get-the-authenticated-user
      #
      def self.authenticated(api_interface)
        api_path = '/user'

        response = api_interface.send_request(api_path)

        new(response.fetch('login'))
      end

      # Returns an array of User instances
      #
      def self.list_collaborators(api_interface)
        api_path = 'collaborators'
        response = api_interface.send_request(api_path, multipage: true)

        response.map { |user_entry| new(user_entry.fetch('login')) }
      end
    end
  end
end
