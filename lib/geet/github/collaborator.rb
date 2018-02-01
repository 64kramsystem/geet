# frozen_string_literal: true

require 'date'

module Geet
  module Github
    class Collaborator
      attr_reader :username

      def initialize(username)
        @username = username
      end

      # Returns an array of Collaborator instances
      def self.list(api_interface)
        api_path = 'collaborators'
        response = api_interface.send_request(api_path, multipage: true)

        response.map { |user_entry| new(user_entry.fetch('login')) }
      end
    end
  end
end
