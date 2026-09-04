# frozen_string_literal: true
# typed: false

require "spec_helper"
load File.expand_path("../../bin/geet", __dir__)

describe GeetLauncher do
  describe "executable entry point" do
    it "recognizes the RubyGems wrapper as the geet executable" do
      original_program_name = $PROGRAM_NAME
      $PROGRAM_NAME = "/path/to/rubygems/bin/geet"

      expect(described_class.run_as_executable?).to be(true)
    ensure
      $PROGRAM_NAME = original_program_name
    end
  end

  describe "#launch" do
    it "dispatches repository creation before constructing an existing repository" do
      service = instance_double(Geet::Services::CreateRepo)
      allow_any_instance_of(Geet::Commandline::Configuration).to receive(:decode_argv).and_return([
        Geet::Commandline::Commands::REPO_CREATE_COMMAND,
        {visibility: "private"},
      ])
      expect(Geet::Services::CreateRepo).to receive(:new).and_return(service)
      expect(service).to receive(:execute).with(visibility: "private")
      expect(Geet::Git::Repository).not_to receive(:new)

      described_class.new.launch
    end

    it "dispatches repository opening without constructing an authenticated repository" do
      service = instance_double(Geet::Services::OpenRepo)
      allow_any_instance_of(Geet::Commandline::Configuration).to receive(:decode_argv).and_return([
        Geet::Commandline::Commands::REPO_OPEN_COMMAND,
        {upstream: true},
      ])
      expect(Geet::Services::OpenRepo).to receive(:new).and_return(service)
      expect(service).to receive(:execute).with(upstream: true)
      expect(Geet::Git::Repository).not_to receive(:new)

      without_token = ENV.delete("GH_TOKEN")
      described_class.new.launch
    ensure
      ENV["GH_TOKEN"] = without_token if without_token
    end

    {
      Geet::Commandline::Commands::LABEL_LIST_COMMAND => Geet::Services::ListLabels,
      Geet::Commandline::Commands::MILESTONE_LIST_COMMAND => Geet::Services::ListMilestones,
      Geet::Commandline::Commands::PR_LIST_COMMAND => Geet::Services::ListPrs,
      Geet::Commandline::Commands::PR_OPEN_COMMAND => Geet::Services::OpenPr,
    }.each do |command, service_class|
      it "dispatches #{command} with an optional API token" do
        launcher = described_class.new
        repository = instance_double(Geet::Git::Repository)
        service = instance_double(service_class)

        allow_any_instance_of(Geet::Commandline::Configuration).to receive(:decode_argv).and_return([command, {}])
        allow(launcher).to receive(:protected_repositories).and_return([])
        expect(Geet::Git::Repository).to receive(:new).with(
          upstream: false,
          protected_repositories: [],
          api_token_required: false
        ).and_return(repository)
        expect(service_class).to receive(:new).with(repository).and_return(service)
        expect(service).to receive(:execute).with(no_args)

        launcher.launch
      end
    end

    it "requires an API token for issue.list" do
      launcher = described_class.new

      allow_any_instance_of(Geet::Commandline::Configuration).to receive(:decode_argv).and_return([
        Geet::Commandline::Commands::ISSUE_LIST_COMMAND,
        {},
      ])
      allow(launcher).to receive(:protected_repositories).and_return([])
      expect(Geet::Services::ListIssues).not_to receive(:new)

      api_token = ENV.delete("GH_TOKEN")
      expect { launcher.launch }.to raise_error("GH_TOKEN not set!")
    ensure
      ENV["GH_TOKEN"] = api_token if api_token
    end
  end
end
