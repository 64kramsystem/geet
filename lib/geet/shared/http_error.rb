# frozen_string_literal: true
# typed: strict

module Geet
  module Shared
    class HttpError < RuntimeError
      extend T::Sig

      sig { returns(Integer) }
      attr_reader :code

      sig { params(message: String, code: T.any(Integer, String)).void }
      def initialize(message, code)
        super(message)
        @code = T.let(code.to_i, Integer)
      end
    end
  end
end
