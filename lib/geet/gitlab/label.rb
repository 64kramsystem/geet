# frozen_string_literal: true
# typed: strict

module Geet
  module Gitlab
    class Label
      extend T::Sig

      sig { returns(String) }
      attr_reader :name

      sig { returns(String) }
      attr_reader :color

      sig {
        params(
          name: String,
          color: String
        ).void
      }
      def initialize(name, color)
        @name = name
        @color = color
      end

      sig {
        params(
          api_interface: ApiInterface
        ).returns(T::Array[Label])
      }
      def self.list(api_interface)
        api_path = "projects/#{api_interface.path_with_namespace(encoded: true)}/labels"
        response = T.cast(
          api_interface.send_request(api_path, multipage: true),
          T::Array[T::Hash[String, T.untyped]]
        )

        response.map do |label_entry|
          name = T.cast(label_entry.fetch('name'), String)
          color = T.cast(label_entry.fetch('color'), String)

          color = color.sub('#', '') # normalize

          new(name, color)
        end
      end

      # See https://docs.gitlab.com/ee/api/labels.html#create-a-new-label
      sig {
        params(
          name: String,
          color: String,
          api_interface: ApiInterface
        ).returns(Label)
      }
      def self.create(name, color, api_interface)
        api_path = "projects/#{api_interface.path_with_namespace(encoded: true)}/labels"
        request_data = { name:, color: "##{color}" }

        api_interface.send_request(api_path, data: request_data)

        new(name, color)
      end
    end
  end
end
