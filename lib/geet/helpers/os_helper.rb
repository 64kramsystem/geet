# frozen_string_literal: true

require 'shellwords'

module Geet
  module Helpers
    module OsHelper
      def os_open(file_or_url)
        if `uname`.strip == 'Darwin'
          exec "open #{file_or_url.shellescape}"
        else
          exec "xdg-open #{file_or_url.shellescape}"
        end
      end
    end
  end
end
