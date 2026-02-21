# frozen_string_literal: true
# typed: strict

require "stringio"

module Geet
  module Services
    class ListLabels
      extend T::Sig

      sig { params(repository: Git::Repository, out: T.any(IO, StringIO)).void }
      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end

      sig {
        returns(T::Array[Github::Label])
      }
      def execute
        labels = @repository.labels

        labels.each do |label|
          @out.puts "- #{label.name} (##{label.color})"
        end
      end
    end
  end
end
