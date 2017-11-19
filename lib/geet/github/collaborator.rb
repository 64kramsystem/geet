# frozen_string_literal: true

require 'date'

module Geet
  module Github
    class Collaborator
      # Returns a flat list of names in string form.
      def self.list(api_interface)
        api_path = 'collaborators'
        response = api_interface.send_request(api_path, multipage: true)

        response.map { |user_entry| user_entry.fetch('login') }
      end
    end
  end
end
