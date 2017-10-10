# frozen_string_literal: true

module Geet
  module GitHub
    class Account
      def initialize(api_helper)
        @api_helper = api_helper
      end

      def authenticated_user
        request_address = 'https://api.github.com/user'

        response = @api_helper.send_request(request_address)

        response.fetch('login')
      end
    end
  end
end
