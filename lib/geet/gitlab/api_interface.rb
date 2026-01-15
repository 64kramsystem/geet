# frozen_string_literal: true
# typed: strict

require 'cgi'
require 'uri'
require 'net/http'
require 'json'

module Geet
  module Gitlab
    class ApiInterface
      extend T::Sig

      API_BASE_URL = 'https://gitlab.com/api/v4'

      sig { returns(T.nilable(String)) }
      attr_reader :repository_path

      # repo_path: "path/namespace"; required for the current GitLab operations.
      # upstream:  boolean; required for the current GitLab operations.
      #
      sig {
        params(
          api_token: String,
          repo_path: String,
          upstream: T::Boolean
        ).void
      }
      def initialize(api_token, repo_path:, upstream:)
        @api_token = api_token
        @path_with_namespace = repo_path
        @upstream = upstream
        @repository_path = T.let(nil, T.nilable(String))
      end

      sig { returns(T::Boolean) }
      def upstream?
        @upstream
      end

      sig {
        params(
          encoded: T::Boolean
        ).returns(String)
      }
      def path_with_namespace(encoded: false)
        encoded ? CGI.escape(@path_with_namespace) : @path_with_namespace
      end

      # Send a request.
      #
      sig {
        params(
          # Appended to the API URL.
          # for root path, prepend a `/`:
          # - use `/gists` for `https://api.github.com/gists`
          # when owner/project/repos is included, don't prepend `/`:
          # - use `issues` for `https://api.github.com/myowner/myproject/repos/issues`
          api_path: String,
          params: T.nilable(T::Hash[Symbol, T.untyped]),
          # If present, will generate a POST request, otherwise, a GET
          data: T.nilable(T.any(T::Hash[Symbol, T.untyped], T::Array[T.untyped])),
          # Set true for paged Github responses (eg. issues); it will make the method
          multipage: T::Boolean,
          # Method (:get, :patch, :post, :put and :delete)
          # :get and :post are automatically inferred by the presence of :data; the other cases must be specified.
          http_method: T.nilable(Symbol)
        # Returns the parsed response, or an Array, in case of multipage.
        # Where no body is present in the response, nil is returned.
        ).returns(T.nilable(T.any(T::Hash[String, T.untyped], T::Array[T::Hash[String, T.untyped]])))
      }
      def send_request(api_path, params: nil, data: nil, multipage: false, http_method: nil)
        address = T.let(api_url(api_path), T.nilable(String))
        # filled only on :multipage
        parsed_responses = []

        loop do
          response = send_http_request(T.must(address), params:, data:, http_method:)

          if response_body = response.body
            parsed_response = JSON.parse(response_body)
          end

          if error?(response)
            formatted_error = decode_and_format_error(T.cast(parsed_response, T::Hash[String, T.untyped]))
            raise(formatted_error)
          end

          return parsed_response if !multipage

          parsed_responses.concat(T.cast(parsed_response, T::Array[T::Hash[String, T.untyped]]))

          address = link_next_page(response.to_hash)

          return parsed_responses if address.nil?

          # Gitlab's next link address already includes all the params, so we remove
          # the passed ones (if there's any).
          params = nil
        end
      end

      private

      sig {
        params(
          api_path: String
        ).returns(String)
      }
      def api_url(api_path)
        "#{API_BASE_URL}/#{api_path}"
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

          request['Private-Token'] = @api_token
          request.body = URI.encode_www_form(data) if data

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
        if parsed_response.key?('error')
          parsed_response.fetch('error')
        elsif parsed_response.key?('message')
          parsed_response.fetch('message')
        else
          "Unrecognized response: #{parsed_response}"
        end
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
          data: T.nilable(Object)
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
