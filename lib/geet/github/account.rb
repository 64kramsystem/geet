# frozen_string_literal: true

module Geet
  module Github
    class Account
      def initialize(api_helper)
        @api_helper = api_helper
      end

      def authenticated_user
        api_path = '/user'

        response = @api_helper.send_request(api_path)

        response.fetch('login')
      end
    end
  end
end
