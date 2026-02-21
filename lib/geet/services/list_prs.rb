# frozen_string_literal: true
# typed: strict

require "stringio"

module Geet
  module Services
    class ListPrs
      extend T::Sig

      sig { params(repository: Git::Repository, out: T.any(IO, StringIO)).void }
      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end

      sig {
        returns(T::Array[Github::PR])
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
