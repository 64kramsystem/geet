# frozen_string_literal: true
# typed: strict

require 'date'

module Geet
  module Gitlab
    class Milestone
      extend T::Sig

      sig { returns(Integer) }
      attr_reader :number

      sig { returns(String) }
      attr_reader :title

      sig { returns(T.nilable(Date)) }
      attr_reader :due_on

      sig {
        params(
          number: Integer,
          title: String,
          due_on: T.nilable(Date),
          api_interface: ApiInterface
        ).void
      }
      def initialize(number, title, due_on, api_interface)
        @number = number
        @title = title
        @due_on = due_on

        @api_interface = api_interface
      end

      # See https://docs.gitlab.com/ee/api/milestones.html#list-project-milestones
      #
      sig {
        params(
          api_interface: ApiInterface
        ).returns(T::Array[Milestone])
      }
      def self.list(api_interface)
        api_path = "projects/#{api_interface.path_with_namespace(encoded: true)}/milestones"

        response = T.cast(
          api_interface.send_request(api_path, multipage: true),
          T::Array[T::Hash[String, T.untyped]]
        )

        response.map do |milestone_data|
          number = T.cast(milestone_data.fetch('iid'), Integer)
          title = T.cast(milestone_data.fetch('title'), String)
          due_on = parse_due_date(
            T.cast(milestone_data.fetch('due_date'), T.nilable(String))
          )

          new(number, title, due_on, api_interface)
        end
      end

      class << self
        extend T::Sig

        private

        sig {
          params(
            raw_due_date: T.nilable(String)
          ).returns(T.nilable(Date))
        }
        def parse_due_date(raw_due_date)
          Date.parse(raw_due_date) if raw_due_date
        end
      end
    end # Milestone
  end # Gitlab
end # Geet
