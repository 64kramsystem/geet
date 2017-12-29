# frozen_string_literal: true

require 'shellwords'

module Geet
  module Helpers
    module OsHelper
      def open_file_with_default_application(file_or_url)
        if `uname`.strip == 'Darwin'
          exec "open #{file_or_url.shellescape}"
        else
          exec "xdg-open #{file_or_url.shellescape}"
        end
      end
    end
  end
end
