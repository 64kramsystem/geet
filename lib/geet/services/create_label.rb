# frozen_string_literal: true
# typed: strict

module Geet
  module Services
    class CreateLabel
      extend T::Sig

      sig { params(repository: T.untyped, out: T.any(IO, StringIO)).void }
      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end

      sig { params(name: String, color: String).returns(T.untyped) }
      def execute(name, color: generate_random_color)
        label = create_label(name, color)

        @out.puts "Created with color ##{label.color}"

        label
      end

      private

      sig { params(name: String, color: String).returns(T.untyped) }
      def create_label(name, color)
        @out.puts 'Creating label...'

        @repository.create_label(name, color)
      end

      # Return a 6-digits hex random color.
      sig { returns(String) }
      def generate_random_color
        hex_number = T.unsafe(rand(2**24)).to_s(16)

        hex_number.rjust(6, '0')
      end
    end
  end
end
