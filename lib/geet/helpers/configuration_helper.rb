# frozen_string_literal: true

require 'simple_scripting/argv'

module Geet
  module Helpers
    class ConfigurationHelper
      LONG_HELP = <<~'STR'
        Usage: github_create.rb pr <title> <description> [label1,label2]

        Creates a PR from the current branch.

        The labels parameter is a comma-separated list of patterns; each pattern is a case-insensitive, partial match of a label.
        If more than one label is found for a pattern, an error is raised.

        Example:

            $ github_create_pr.rb 'My Title' "This is
            a long description, but don't worry, it will be escaped.
            Just make sure to handle the quotes properly, since it's a shell string!" legacy,swf

        The above will:

        - create a PR with given title/description
        - assign the authenticated user to the PR
        - add the "Tests: Legacy" and "Needs SWF Rebuild" labels to the PR
        - open the PR (in the browser session)
      STR

      def decode_argv
        SimpleScripting::Argv.decode(
          'pr' => [
            ['-n', '--no-open-pr',                              "Don't open the PR link in the browser after creation"],
            ['-l', '--label-patterns "legacy,code review"',     'Label patterns'],
            ['-r', '--reviewer-patterns john,tom,adrian,kevin', 'Reviewer login patterns'],
            'title',
            'description'
          ],
          long_help: LONG_HELP
        )
      end

      def api_token
        ENV['GITHUB_API_TOKEN'] || raise('Missing $GITHUB_API_TOKEN')
      end
    end
  end
end
