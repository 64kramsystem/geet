# frozen_string_literal: true

require_relative '../helpers/os_helper.rb'
require_relative '../git/repository.rb'

module Geet
  module Services
    class CreatePr
      include Geet::Helpers::OsHelper

      # options:
      #   :label_patterns
      #   :reviewer_patterns
      #   :no_open_pr
      #
      def execute(repository, title, description, options = {})
        if options[:label_patterns]
          puts 'Finding labels...'

          all_labels = repository.labels
          selected_labels = select_entries(all_labels, options[:label_patterns], type: 'labels')
        end

        if options[:reviewer_patterns]
          puts 'Finding collaborators...'

          all_collaborators = repository.collaborators
          reviewers = select_entries(all_collaborators, options[:reviewer_patterns], type: 'collaborators')
        end

        puts 'Creating PR...'

        pr = repository.create_pr(title, description)

        puts 'Assigning authenticated user...'

        pr.assign_user(repository.authenticated_user)

        if selected_labels
          puts 'Adding labels...'

          pr.add_labels(selected_labels)

          puts '- labels added: ' + selected_labels.join(', ')
        end

        if reviewers
          puts 'Requesting review...'

          pr.request_review(reviewers)

          puts '- review requested to: ' + reviewers.join(', ')
        end

        if options[:no_open_pr]
          puts "PR address: #{pr.link}"
        else
          os_open(pr.link)
        end
      end

      private

      def select_entries(entries, raw_patterns, type: 'entries')
        patterns = raw_patterns.split(',')

        patterns.map do |pattern|
          entries_found = entries.select { |label| label =~ /#{pattern}/i }

          case entries_found.size
          when 1
            entries_found.first
          when 0
            raise "No #{type} found for pattern: #{pattern.inspect}"
          else
            raise "Multiple #{type} found for pattern #{pattern.inspect}: #{entries_found}"
          end
        end
      end
    end
  end
end
