# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'json'
require 'shellwords'

module Geet
  module GitHub
    class ApiHelper
      API_AUTH_USER = '' # We don't need the login, as the API key uniquely identifies the user
      API_BASE_URL = 'https://api.github.com'

      def initialize(api_token, repository_path, upstream)
        @api_token = api_token
        @repository_path = repository_path
        @upstream = upstream
      end

      def upstream?
        @upstream
      end

      # Send a request.
      #
      # Returns the parsed response, or an Array, in case of multipage.
      #
      # params:
      #   :api_path:    api path, will be appended to the API URL.
      #                 for root path, prepend a `/`:
      #                 - use `/gists` for `https://api.github.com/gists`
      #                 when owner/project/repos is included, don't prepend `/`:
      #                 - use `issues` for `https://api.github.com/myowner/myproject/repos/issues`
      #   :params:      (Hash)
      #   :data:        (Hash) if present, will generate a POST request, otherwise, a GET
      #   :multipage:   set true for paged GitHub responses (eg. issues); it will make the method
      #                 return an array, with the concatenated (parsed) responses
      #   :http_method: :get, :patch, :post and :put are accepted, but only :patch/:put are meaningful,
      #                 since the others are automatically inferred by :data.
      #
      def send_request(api_path, params: nil, data: nil, multipage: false, http_method: nil)
        address = api_url(api_path)
        # filled only on :multipage
        parsed_responses = []

        loop do
          response = send_http_request(address, params: params, data: data, http_method: http_method)

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

      def api_url(api_path)
        url = API_BASE_URL
        url += "/repos/#{@repository_path}/" if !api_path.start_with?('/')
        url + api_path
      end

      def send_http_request(address, params: nil, data: nil, http_method: nil)
        uri = encode_uri(address, params)
        http_class = find_http_class(http_method, data)

        Net::HTTP.start(uri.host, use_ssl: true) do |http|
          request = http_class.new(uri)

          request.basic_auth API_AUTH_USER, @api_token
          request.body = data.to_json if data
          request['Accept'] = 'application/vnd.github.v3+json'

          http.request(request)
        end
      end

      def encode_uri(address, params)
        address += '?' + URI.encode_www_form(params) if params

        URI(address)
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

      def find_http_class(http_method, data)
        http_method ||= data ? :post : :get

        case http_method
        when :get
          Net::HTTP::Get
        when :patch
          Net::HTTP::Patch
        when :put
          Net::HTTP::Put
        when :post
          Net::HTTP::Post
        else
          raise "Unsupported HTTP method: #{http_method.inspect}"
        end
      end
    end
  end
end
