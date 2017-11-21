# frozen_string_literal: true

module Geet
  module Services
    class ListPrs
      def execute(repository, output: $stdout)
        prs = repository.prs

        prs.each do |pr|
          output.puts "#{pr.number}. #{pr.title} (#{pr.link})"
        end
      end
    end
  end
end
