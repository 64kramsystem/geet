# frozen_string_literal: true
# typed: strict

require 'uri'
require 'net/http'
require 'json'

module Geet
  module Github
    class ApiInterface
      extend T::Sig

      API_AUTH_USER = T.let('', String) # We don't need the login, as the API key uniquely identifies the user
      API_BASE_URL = T.let('https://api.github.com', String)
      GRAPHQL_API_URL = T.let('https://api.github.com/graphql', String)

      sig { returns(T.nilable(String)) }
      attr_reader :repository_path

      # repo_path: optional for operations that don't require a repository, eg. gist creation.
      # upstream:  boolean; makes sense only when :repo_path is set.
      #
      sig {
        params(
          api_token: String,
          repo_path: T.nilable(String),
          upstream: T.nilable(T::Boolean)
        ).void
      }
      def initialize(api_token, repo_path: nil, upstream: nil)
        @api_token = T.let(api_token, String)
        @repository_path = T.let(repo_path, T.nilable(String))
        @upstream = T.let(upstream, T.nilable(T::Boolean))
      end

      sig { returns(T.nilable(T::Boolean)) }
      def upstream?
        @upstream
      end

      # Send a request.
      #
      # Returns the parsed response, or an Array, in case of multipage.
      # Where no body is present in the response, nil is returned.
      #
      # params:
      #   :api_path:    api path, will be appended to the API URL.
      #                 for root path, prepend a `/`:
      #                 - use `/gists` for `https://api.github.com/gists`
      #                 when owner/project/repos is included, don't prepend `/`:
      #                 - use `issues` for `https://api.github.com/myowner/myproject/repos/issues`
      #   :params:      (Hash)
      #   :data:        (Hash) if present, will generate a POST request, otherwise, a GET
      #   :multipage:   set true for paged Github responses (eg. issues); it will make the method
      #                 return an array, with the concatenated (parsed) responses
      #   :http_method: symbol format of the method (:get, :patch, :post, :put and :delete)
      #                 :get and :post are automatically inferred by the present of :data; the other
      #                 cases must be specified.
      #
      sig {
        params(
          api_path: String,
          params: T.nilable(T::Hash[Symbol, T.untyped]),
          data: T.nilable(T.any(T::Hash[Symbol, T.untyped], T::Array[T.untyped])),
          multipage: T::Boolean,
          http_method: T.nilable(Symbol)
        ).returns(T.any(T::Hash[String, T.untyped], T::Array[T::Hash[String, T.untyped]], NilClass))
      }
      def send_request(api_path, params: nil, data: nil, multipage: false, http_method: nil)
        address = T.let(api_url(api_path), T.nilable(String))
        # filled only on :multipage
        parsed_responses = T.let([], T::Array[T::Hash[String, T.untyped]])

        loop do
          response = send_http_request(T.must(address), params:, data:, http_method:)

          parsed_response = T.unsafe(JSON.parse(T.must(response.body))) if response.body

          if error?(response)
            error_message = decode_and_format_error(T.cast(parsed_response, T::Hash[String, T.untyped]))
            raise Geet::Shared::HttpError.new(error_message, response.code)
          end

          return parsed_response if !multipage

          parsed_responses.concat(T.cast(parsed_response, T::Array[T::Hash[String, T.untyped]]))

          address = link_next_page(response.to_hash)

          return parsed_responses if address.nil?
        end
      end

      # Send a GraphQL request.
      #
      # Returns the parsed response data.
      #
      # params:
      #   :query:       GraphQL query string
      #   :variables:   (Hash) GraphQL variables
      #
      sig {
        params(
          query: String,
          variables: T::Hash[Symbol, T.untyped]
        ).returns(T::Hash[String, T.untyped])
      }
      def send_graphql_request(query, variables: {})
        uri = URI(GRAPHQL_API_URL)

        Net::HTTP.start(uri.host, use_ssl: true) do |http|
          request = Net::HTTP::Post.new(uri).tap do
            it.basic_auth API_AUTH_USER, @api_token
            it['Accept'] = 'application/vnd.github.v3+json'
            it.body = {query:, variables:}.to_json
          end

          response = http.request(request)

          parsed_response = T.let(nil, T.nilable(T::Hash[String, T.untyped]))
          if response.body
            parsed_response = T.cast(T.unsafe(JSON.parse(response.body)), T::Hash[String, T.untyped])
          end

          if error?(response)
            error_message = decode_and_format_error(T.must(parsed_response))
            raise Geet::Shared::HttpError.new(error_message, response.code)
          end

          if parsed_response&.key?('errors')
            error_messages = T.cast(parsed_response['errors'], T::Array[T::Hash[String, T.untyped]]).map { |err| T.cast(err['message'], String) }.join(', ')
            raise Geet::Shared::HttpError.new("GraphQL errors: #{error_messages}", response.code)
          end

          T.cast(T.must(parsed_response).fetch('data'), T::Hash[String, T.untyped])
        end
      end

      private

      sig {
        params(
          api_path: String
        ).returns(String)
      }
      def api_url(api_path)
        url = API_BASE_URL

        if !api_path.start_with?('/')
          raise 'Missing repo path!' if @repository_path.nil?
          url += "/repos/#{@repository_path}/"
        end

        url + api_path
      end

      sig {
        params(
          address: String,
          params: T.nilable(T::Hash[Symbol, T.untyped]),
          data: T.nilable(T.any(T::Hash[Symbol, T.untyped], T::Array[T.untyped])),
          http_method: T.nilable(Symbol)
        ).returns(Net::HTTPResponse)
      }
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

      sig {
        params(
          address: String,
          params: T.nilable(T::Hash[Symbol, T.untyped])
        ).returns(URI::Generic)
      }
      def encode_uri(address, params)
        address += '?' + URI.encode_www_form(params) if params

        URI(address)
      end

      sig {
        params(
          response: Net::HTTPResponse
        ).returns(T::Boolean)
      }
      def error?(response)
        !response.code.start_with?('2')
      end

      sig {
        params(
          parsed_response: T::Hash[String, T.untyped]
        ).returns(String)
      }
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

      sig {
        params(
          response_headers: T::Hash[String, T.untyped]
        ).returns(T.nilable(String))
      }
      def link_next_page(response_headers)
        # An array (or nil) is returned.
        link_header = Array(response_headers['link'])

        return nil if link_header.empty?

        link_header[0][/<(\S+)>; rel="next"/, 1]
      end

      sig {
        params(
          http_method: T.nilable(Symbol),
          data: T.nilable(T.any(T::Hash[Symbol, T.untyped], T::Array[T.untyped]))
        ).returns(T.class_of(Net::HTTPRequest))
      }
      def find_http_class(http_method, data)
        http_method ||= data ? :post : :get

        case http_method
        when :get
          Net::HTTP::Get
        when :delete
          Net::HTTP::Delete
        when :patch
          Net::HTTP::Patch
        when :post
          Net::HTTP::Post
        when :put
          Net::HTTP::Put
        else
          raise "Unsupported HTTP method: #{http_method.inspect}"
        end
      end
    end
  end
end
