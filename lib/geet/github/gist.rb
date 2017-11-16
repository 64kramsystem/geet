# frozen_string_literal: true

require_relative 'abstract_issue'

module Geet
  module Github
    class Gist
      def self.create(filename, content, api_helper, description: nil, publik: false)
        api_path = "/gists"

        request_data = prepare_request_data(filename, content, description, publik)

        response = api_helper.send_request(api_path, data: request_data)

        id = response.fetch('id')

        new(id)
      end

      def initialize(id)
        @id = id
      end

      def link
        "https://gist.github.com/#{@id}"
      end

      class << self
        private

        def prepare_request_data(filename, content, description, publik)
          request_data = {
            'public' => publik,
            'files' => {
              filename => {
                'content' => content
              }
            }
          }

          request_data['description'] = description if description

          request_data
        end
      end
    end
  end
end
