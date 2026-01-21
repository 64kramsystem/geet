# frozen_string_literal: true
# typed: strict

require_relative "abstract_issue"
require_relative "../github/gist"

module Geet
  module Github
    class Gist
      extend T::Sig

      sig {
        params(
          filename: String,
          content: String,
          api_interface: Geet::Github::ApiInterface,
          description: T.nilable(String),
          publik: T::Boolean
        ).returns(Geet::Github::Gist)
      }
      def self.create(filename, content, api_interface, description: nil, publik: false)
        api_path = "/gists"

        request_data = prepare_request_data(filename, content, description, publik)

        response = T.cast(api_interface.send_request(api_path, data: T.unsafe(request_data)), T::Hash[String, T.untyped])

        id = T.cast(response.fetch("id"), String)

        new(id)
      end

      sig { params(id: String).void }
      def initialize(id)
        @id = id
      end

      sig { returns(String) }
      def link
        "https://gist.github.com/#{@id}"
      end

      class << self
        extend T::Sig

        private

        sig {
          params(
            filename: String,
            content: String,
            description: T.nilable(String),
            publik: T::Boolean
          ).returns(T::Hash[String, T.untyped])
        }
        def prepare_request_data(filename, content, description, publik)
          request_data = {
            "public" => publik,
            "files" => {
              filename => {
                "content" => content,
              },
            },
          }

          request_data["description"] = description if description

          request_data
        end
      end
    end
  end
end
