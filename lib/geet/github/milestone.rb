# frozen_string_literal: true

require_relative '../helpers/json_helper'

module Geet
  module Github
    class Milestone
      attr_reader :number, :title, :due_on

      STATE_CLOSED = 'closed'

      class << self
        private

        include Helpers::JsonHelper
      end

      def initialize(number, title, due_on, api_interface)
        @number = number
        @title = title
        @due_on = due_on

        @api_interface = api_interface
      end

      # See https://developer.github.com/v3/issues/milestones/#create-a-milestone
      def self.create(title, api_interface, **)
        api_path = 'milestones'
        request_data = { title: title }

        response = api_interface.send_request(api_path, data: request_data)

        number = response.fetch('number')
        title = response.fetch('title')
        due_on = nil

        new(number, title, due_on, api_interface)
      end

      # See https://developer.github.com/v3/issues/milestones/#get-a-single-milestone
      #
      def self.find(number, api_interface)
        api_path = "milestones/#{number}"

        response = api_interface.send_request(api_path)

        number = response.fetch('number')
        title = response.fetch('title')
        due_on = parse_iso_8601_timestamp(raw_due_on)

        new(number, title, due_on, api_interface)
      end

      # See https://developer.github.com/v3/issues/milestones/#list-milestones-for-a-repository
      #
      def self.list(api_interface, **)
        api_path = 'milestones'

        response = api_interface.send_request(api_path, multipage: true)

        response.map do |milestone_data|
          number = milestone_data.fetch('number')
          title = milestone_data.fetch('title')
          due_on = parse_iso_8601_timestamp(milestone_data.fetch('due_on'))

          new(number, title, due_on, api_interface)
        end
      end

      # See https://docs.github.com/en/free-pro-team@latest/rest/reference/issues#update-a-milestone
      #
      # This is a convenience method; the underlying operation is a generic update.
      #
      def self.close(number, api_interface)
        api_path = "milestones/#{number}"
        request_data = { state: STATE_CLOSED }

        api_interface.send_request(api_path, data: request_data)
      end
    end
  end
end
