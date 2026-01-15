# frozen_string_literal: true
# typed: strict

module Geet
  module Services
    class ListPrs
      extend T::Sig

      sig { params(repository: T.untyped, out: T.any(IO, StringIO)).void }
      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end

      sig {
        returns(T::Array[T.any(Github::PR, Gitlab::PR)])
      }
      def execute
        prs = @repository.prs

        prs.each do |pr|
          @out.puts "#{pr.number}. #{pr.title} (#{pr.link})"
        end
      end
    end
  end
end
