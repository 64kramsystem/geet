# frozen_string_literal: true

require "spec_helper"

require_relative "../../lib/geet/git/repository"
require_relative "../../lib/geet/services/open_repo"

module Geet
  describe Services::OpenRepo do
    let(:git_client) { Utils::GitClient.new }
    let(:repository) { Git::Repository.new(git_client: git_client) }

    OWNER = "donaldduck"
    REPOSITORY_NAME = "testrepo"

    REMOTE_URLS = {
      "git" => "git@github.com:#{OWNER}/#{REPOSITORY_NAME}",
      "https" => "https://github.com/#{OWNER}/#{REPOSITORY_NAME}",
    }

    context "should open the PR for the current branch" do
      REMOTE_URLS.each do |protocol, remote_url|
        it "with #{protocol} protocol" do
          allow(git_client).to receive(:remote).with(no_args).and_return(remote_url)

          expected_url = "https://github.com/#{OWNER}/#{REPOSITORY_NAME}"
          expected_output = ""

          expect {
            service_instance = described_class.new(repository, git_client: git_client)

            expect(service_instance).to receive(:open_file_with_default_application).with(expected_url) do
              # do nothing; just don't open the browser
            end

            execution_result = VCR.use_cassette("github_com/open_repo") do
              service_instance.execute
            end

            expect(execution_result).to eql(expected_url)
          }.to output(expected_output).to_stdout
        end
      end
    end # context 'should open the PR for the current branch'
  end # describe Services::OpenRepo
end # module Geet
