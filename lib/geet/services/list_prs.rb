# frozen_string_literal: true

module Geet
  module Services
    class ListPrs
      def execute(repository)
        prs = repository.prs

        prs.each do |pr|
          puts "#{pr.number}. #{pr.title} (#{pr.link})"
        end
      end
    end
  end
end
