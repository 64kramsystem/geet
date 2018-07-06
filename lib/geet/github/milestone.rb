# frozen_string_literal: true

require_relative '../helpers/json_helper'

module Geet
  module Github
    class Milestone
      attr_reader :number, :title, :due_on

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

      # Endpoint: https://developer.github.com/v3/issues/milestones/#get-a-single-milestone
      #
      def self.find(number, api_interface)
        api_path = "milestones/#{number}"

        response = api_interface.send_request(api_path)

        number = response.fetch('number')
        title = response.fetch('title')
        due_on = parse_iso_8601_timestamp(raw_due_on)

        new(number, title, due_on, api_interface)
      end

      # Endpoint: https://developer.github.com/v3/issues/milestones/#list-milestones-for-a-repository
      #
      def self.list(api_interface)
        api_path = 'milestones'

        response = api_interface.send_request(api_path, multipage: true)

        response.map do |milestone_data|
          number = milestone_data.fetch('number')
          title = milestone_data.fetch('title')
          due_on = parse_iso_8601_timestamp(milestone_data.fetch('due_on'))

          new(number, title, due_on, api_interface)
        end
      end
    end
  end
end
