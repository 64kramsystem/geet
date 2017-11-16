# frozen_string_literal: true

require_relative '../helpers/os_helper.rb'

module Geet
  module Services
    class CreateGist
      include Geet::Helpers::OsHelper

      # options:
      #   :description
      #   :publik:      defaults to false
      #   :no_browse    defaults to false
      #
      def execute(repository, full_filename, description: nil, publik: false, no_browse: false)
        content = IO.read(full_filename)

        puts 'Creating the gist...'

        filename = File.basename(full_filename)
        gist = repository.create_gist(filename, content, description: description, publik: publik)

        if no_browse
          puts "Gist address: #{gist.link}"
        else
          os_open(gist.link)
        end
      end
    end
  end
end
