# frozen_string_literal: true
# typed: strict

module Geet
  module Github
    class Milestone
      extend T::Sig

      sig { returns(Integer) }
      attr_reader :number

      sig { returns(String) }
      attr_reader :title

      sig { returns(T.nilable(Date)) }
      attr_reader :due_on

      STATE_CLOSED = "closed"

      class << self
        extend T::Sig

        private

        include Helpers::JsonHelper
      end

      sig {
        params(
          number: Integer,
          title: String,
          due_on: T.nilable(Date),
          api_interface: Geet::Github::ApiInterface
        ).void
      }
      def initialize(number, title, due_on, api_interface)
        @number = number
        @title = title
        @due_on = due_on

        @api_interface = api_interface
      end

      # See https://developer.github.com/v3/issues/milestones/#create-a-milestone
      sig {
        params(
          title: String,
          api_interface: Geet::Github::ApiInterface
        ).returns(Geet::Github::Milestone)
      }
      def self.create(title, api_interface)
        api_path = "milestones"
        request_data = {title: title}

        response = T.cast(
          api_interface.send_request(api_path, data: request_data),
          T::Hash[String, T.untyped]
        )

        number = T.cast(response.fetch("number"), Integer)
        title = T.cast(response.fetch("title"), String)
        due_on = nil

        new(number, title, due_on, api_interface)
      end

      # See https://developer.github.com/v3/issues/milestones/#list-milestones-for-a-repository
      #
      sig {
        params(
          api_interface: Geet::Github::ApiInterface
        ).returns(T::Array[Geet::Github::Milestone])
      }
      def self.list(api_interface)
        api_path = "milestones"

        response = T.cast(
          api_interface.send_request(api_path, multipage: true),
          T::Array[T::Hash[String, T.untyped]]
        )

        response.map do |milestone_data|
          number = T.cast(milestone_data.fetch("number"), Integer)
          title = T.cast(milestone_data.fetch("title"), String)
          due_on = parse_iso_8601_timestamp(
            T.cast(milestone_data.fetch("due_on"), T.nilable(String))
          )

          new(number, title, due_on, api_interface)
        end
      end

      # See https://docs.github.com/en/free-pro-team@latest/rest/reference/issues#update-a-milestone
      #
      # This is a convenience method; the underlying operation is a generic update.
      #
      sig {
        params(
          number: Integer,
          api_interface: Geet::Github::ApiInterface
        ).void
      }
      def self.close(number, api_interface)
        api_path = "milestones/#{number}"
        request_data = {state: STATE_CLOSED}

        api_interface.send_request(api_path, data: request_data)
      end
    end
  end
end
