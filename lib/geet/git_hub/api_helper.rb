# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'json'
require 'shellwords'

module Geet
  module GitHub
    class ApiHelper
      def initialize(api_token, user, repository_path, upstream)
        @api_token = api_token
        @user = user
        @repository_path = repository_path
        @upstream = upstream
      end

      def api_base_link
        'https://api.github.com'
      end

      def api_repo_link
        "#{api_base_link}/repos/#{@repository_path}"
      end

      def repo_link
        "https://github.com/#{@repository_path}"
      end

      def upstream?
        @upstream
      end

      # Send a request.
      #
      # Returns the parsed response, or an Array, in case of multipage.
      #
      # params:
      #   :data:        (Hash) if present, will generate a POST request
      #   :multipage:   set true for paged GitHub responses (eg. issues); it will make the method
      #                 return an array, with the concatenated (parsed) responses
      #
      def send_request(address, data: nil, multipage: false)
        # filled only on :multipage
        parsed_responses = []

        loop do
          response = send_http_request(address, data: data)

          parsed_response = JSON.parse(response.body)

          if error?(response)
            formatted_error = decode_and_format_error(parsed_response)
            raise(formatted_error)
          end

          return parsed_response if !multipage

          parsed_responses.concat(parsed_response)

          address = link_next_page(response.to_hash)

          return parsed_responses if address.nil?
        end
      end

      private

      def send_http_request(address, data: nil)
        uri = URI(address)

        Net::HTTP.start(uri.host, use_ssl: true) do |http|
          if data
            request = Net::HTTP::Post.new(uri)
            request.body = data.to_json
          else
            request = Net::HTTP::Get.new(uri)
          end

          request.basic_auth @user, @api_token
          request['Accept'] = 'application/vnd.github.v3+json'

          http.request(request)
        end
      end

      def error?(response)
        !response['Status'].start_with?('2')
      end

      def decode_and_format_error(parsed_response)
        message = parsed_response['message']

        if parsed_response.key?('errors')
          message += ':'

          error_details = parsed_response['errors'].map do |error_data|
            error_code = error_data.fetch('code')

            if error_code == 'custom'
              " #{error_data.fetch('message')}"
            else
              " #{error_code} (#{error_data.fetch('field')})"
            end
          end

          message += error_details.join(', ')
        end

        message
      end

      def link_next_page(response_headers)
        # An array (or nil) is returned.
        link_header = Array(response_headers['link'])

        return nil if link_header.empty?

        link_header[0][/<(\S+)>; rel="next"/, 1]
      end
    end
  end
end
