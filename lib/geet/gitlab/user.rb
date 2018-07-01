# frozen_string_literal: true

module Geet
  module Gitlab
    class User
      attr_reader :id, :username

      def initialize(id, username, api_interface)
        @id = id
        @username = username
        @api_interface = api_interface
      end

      # Returns an array of User instances
      #
      def self.list_collaborators(api_interface)
        api_path = "projects/#{api_interface.path_with_namespace(encoded: true)}/members"

        response = api_interface.send_request(api_path, multipage: true)

        response.map do |user_entry|
          id = user_entry.fetch('id')
          username = user_entry.fetch('username')

          new(id, username, api_interface)
        end
      end
    end # User
  end # Gitlab
end # Geet
