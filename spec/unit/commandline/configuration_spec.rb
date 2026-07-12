# frozen_string_literal: true
# typed: false

require "spec_helper"

describe Geet::Commandline::Configuration do
  describe "#decode_argv" do
    it "decodes long repository creation options" do
      stub_const("ARGV", [
        "repo", "create",
        "--visibility", "private",
        "--upstream", "git@github.com:owner/project.git",
      ])

      expect(described_class.new.decode_argv).to eq([
        "repo.create",
        {visibility: "private", upstream: "git@github.com:owner/project.git"},
      ])
    end

    it "decodes short repository creation options" do
      stub_const("ARGV", [
        "repo", "create",
        "-v", "public",
        "-u", "https://github.com/owner/project.git",
      ])

      expect(described_class.new.decode_argv).to eq([
        "repo.create",
        {visibility: "public", upstream: "https://github.com/owner/project.git"},
      ])
    end
  end
end
