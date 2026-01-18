# frozen_string_literal: true
# typed: strict

module Geet
  module Github
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
          api_interface: Geet::Github::ApiInterface
        ).returns(T::Array[Geet::Github::Label])
      }
      def self.list(api_interface)
        api_path = 'labels'
        response = T.cast(api_interface.send_request(api_path, multipage: true), T::Array[T::Hash[String, T.untyped]])

        response.map do |label_entry|
          name = T.cast(label_entry.fetch('name'), String)
          color = T.cast(label_entry.fetch('color'), String)

          new(name, color)
        end
      end

      # See https://developer.github.com/v3/issues/labels/#create-a-label
      sig {
        params(
          name: String,
          color: String,
          api_interface: Geet::Github::ApiInterface
        ).returns(Geet::Github::Label)
      }
      def self.create(name, color, api_interface)
        api_path = 'labels'
        request_data = {name:, color:}

        api_interface.send_request(api_path, data: request_data)

        new(name, color)
      end
    end
  end
end
