# frozen_string_literal: true

module Geet
  module Gitlab
    class Label
      attr_reader :name, :color

      def initialize(name, color)
        @name = name
        @color = color
      end

      # Returns a flat list of names in string form.
      def self.list(api_interface)
        api_path = "projects/#{api_interface.path_with_namespace(encoded: true)}/labels"
        response = api_interface.send_request(api_path, multipage: true)

        response.map do |label_entry|
          name = label_entry.fetch('name')
          color = label_entry.fetch('color').sub('#', '') # normalize

          new(name, color)
        end
      end
    end
  end
end
