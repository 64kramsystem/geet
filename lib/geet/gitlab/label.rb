# frozen_string_literal: true

require 'date'

module Geet
  module Gitlab
    class Label
      # Returns a flat list of names in string form.
      def self.list(api_interface)
        api_path = "projects/#{api_interface.path_with_namespace(encoded: true)}/labels"
        response = api_interface.send_request(api_path, multipage: true)

        response.map { |label_entry| label_entry.fetch('name') }
      end
    end
  end
end
