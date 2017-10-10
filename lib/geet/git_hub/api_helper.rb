# frozen_string_literal: true

require 'json'
require 'open3'
require 'shellwords'

module Geet
  module GitHub
    class ApiHelper
      def initialize(api_token, user, owner, repo)
        @api_token = api_token
        @user = user
        @owner = owner
        @repo = repo
      end

      def repo_link
        "https://api.github.com/repos/#{@owner}/#{@repo}"
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
        # `--data` implies `-X POST`
        #
        if data
          escaped_request_body = JSON.generate(data).shellescape
          data_option = "--data #{escaped_request_body}"
        end

        # filled only on :multipage
        parsed_responses = []

        loop do
          command = %(curl --verbose --silent --user "#{@user}:#{@api_token}" #{data_option} #{address})
          response_metadata, response_body = nil

          Open3.popen3(command) do |_, stdout, stderr, wait_thread|
            response_metadata = stderr.readlines.join
            response_body = stdout.readlines.join

            if !wait_thread.value.success?
              puts response_metadata
              puts "Error! Command: #{command}"
              exit
            end
          end

          parsed_response = JSON.parse(response_body)

          if error?(response_metadata)
            formatted_error = decode_and_format_error(parsed_response)
            raise(formatted_error)
          end

          return parsed_response if !multipage

          parsed_responses.concat(parsed_response)

          address = link_next_page(response_metadata)

          return parsed_responses if address.nil?
        end
      end

      private

      def decode_and_format_error(response)
        message = response['message']

        if response.key?('errors')
          message += ':'

          error_details = response['errors'].map do |error_data|
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

      def error?(response_metadata)
        status_header = find_header_content(response_metadata, 'Status')

        !!(status_header =~ /^4\d\d/)
      end

      def link_next_page(response_metadata)
        link_header = find_header_content(response_metadata, 'Link')

        return nil if link_header.nil?

        link_header[/<(\S+)>; rel="next"/, 1]
      end

      def find_header_content(response_metadata, header_name)
        response_metadata.split("\n").each do |header|
          return Regexp.last_match(1) if header =~ /^< #{header_name}: (.*)/
        end

        nil
      end
    end
  end
end
