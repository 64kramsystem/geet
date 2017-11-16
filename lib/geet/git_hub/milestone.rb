# frozen_string_literal: true

require 'date'

module Geet
  module GitHub
    class Milestone
      attr_reader :number, :title, :due_on

      def initialize(number, title, due_on, api_helper)
        @number = number
        @title = title
        @due_on = due_on

        @api_helper = api_helper
      end

      # See https://developer.github.com/v3/issues/milestones/#get-a-single-milestone
      #
      def self.find(number, api_helper)
        api_path = "milestones/#{number}"

        response = api_helper.send_request(api_path)

        number = response.fetch('number')
        title = response.fetch('title')
        due_on = parse_due_on(response.fetch('due_on'))

        new(number, title, due_on, api_helper)
      end

      # See https://developer.github.com/v3/issues/milestones/#list-milestones-for-a-repository
      #
      def self.list(api_helper)
        api_path = 'milestones'

        response = api_helper.send_request(api_path, multipage: true)

        response.map do |milestone_data|
          number = milestone_data.fetch('number')
          title = milestone_data.fetch('title')
          due_on = parse_due_on(milestone_data.fetch('due_on'))

          new(number, title, due_on, api_helper)
        end
      end

      class << self
        private

        def parse_due_on(raw_due_on)
          Date.strptime(raw_due_on, '%FT%TZ') if raw_due_on
        end
      end
    end
  end
end
