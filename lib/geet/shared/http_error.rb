module Geet
  module Shared
    class HttpError < RuntimeError
      # Integer.
      attr_reader :code

      def initialize(message, code)
        super(message)
        @code = code.to_i
      end
    end
  end
end
