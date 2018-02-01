# frozen_string_literal: true

module Geet
  module Github
    class Label
      attr_reader :name, :color

      def initialize(name, color)
        @name = name
        @color = color
      end

      # Returns a flat list of names in string form.
      def self.list(api_interface)
        api_path = 'labels'
        response = api_interface.send_request(api_path, multipage: true)

        response.map do |label_entry|
          name = label_entry.fetch('name')
          color = label_entry.fetch('color')

          new(name, color)
        end
      end

      # See https://developer.github.com/v3/issues/labels/#create-a-label
      def self.create(name, color, api_interface)
        api_path = 'labels'
        request_data = { name: name, color: color }

        api_interface.send_request(api_path, data: request_data)

        new(name, color)
      end
    end
  end
end
