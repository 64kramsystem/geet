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
      def execute(repository, full_filename, description: nil, publik: false, no_browse: false, output: $stdout)
        content = IO.read(full_filename)

        gist_access = publik ? 'public' : 'private'
        output.puts "Creating a #{gist_access} gist..."

        filename = File.basename(full_filename)
        gist = repository.create_gist(filename, content, description: description, publik: publik)

        if no_browse
          output.puts "Gist address: #{gist.link}"
        else
          os_open(gist.link)
        end
      end
    end
  end
end
