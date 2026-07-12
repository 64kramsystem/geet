# frozen_string_literal: true
# typed: false

require "spec_helper"
load File.expand_path("../../bin/geet", __dir__)

describe GeetLauncher do
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
  end
end
