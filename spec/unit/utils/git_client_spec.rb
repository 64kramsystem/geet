# frozen_string_literal: true

require "spec_helper"

describe Geet::Utils::GitClient do
  subject { described_class.new }

  describe "#head_commit?" do
    it "returns true when HEAD resolves" do
      allow(subject).to receive(:execute_git_command).with("rev-parse --verify HEAD", allow_error: true, silent_stderr: true).and_return("abc123")
      expect(subject.head_commit?).to be(true)
    end

    it "returns false for an unborn HEAD" do
      allow(subject).to receive(:execute_git_command).with("rev-parse --verify HEAD", allow_error: true, silent_stderr: true).and_return("")
      expect(subject.head_commit?).to be(false)
    end
  end

  describe "#remote_path" do
    it "extracts an SSH repository path" do
      expect(subject.remote_path("git@github.com:owner/project.git")).to eq("owner/project")
    end

    it "extracts an HTTPS repository path" do
      expect(subject.remote_path("https://github.com/owner/project.git")).to eq("owner/project")
    end

    it "rejects an unsupported address" do
      expect { subject.remote_path("owner/project") }.to raise_error(RuntimeError, 'Unexpected remote reference format: "owner/project"')
    end
  end
end
