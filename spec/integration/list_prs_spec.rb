# frozen_string_literal: true

require "spec_helper"

require_relative "../../lib/geet/git/repository"
require_relative "../../lib/geet/services/list_prs"

describe Geet::Services::ListPrs do
  let(:git_client) { Geet::Utils::GitClient.new }
  let(:repository) { Geet::Git::Repository.new(git_client: git_client) }
  let(:upstream_repository) { Geet::Git::Repository.new(upstream: true, git_client: git_client) }

  it "should list the PRs" do
    allow(git_client).to receive(:remote).with(no_args).and_return("git@github.com:donald-fr/testrepo_downstream")

    expected_output = <<~STR
      2. Add testfile3 (downstream) (https://github.com/donald-fr/testrepo_downstream/pull/2)
      1. Add testfile2 (downstream) (https://github.com/donald-fr/testrepo_downstream/pull/1)
    STR
    expected_pr_numbers = [2, 1]

    actual_output = StringIO.new

    service_result = VCR.use_cassette("list_prs") do
      described_class.new(repository, out: actual_output).execute
    end

    actual_pr_numbers = service_result.map(&:number)

    expect(actual_output.string).to eql(expected_output)
    expect(actual_pr_numbers).to eql(expected_pr_numbers)
  end

  it "should list the upstream PRs" do
    allow(git_client).to receive(:remote).with(no_args).and_return("git@github.com:donald-fr/testrepo_downstream")
    allow(git_client).to receive(:remote).with(name: "upstream").and_return("git@github.com:donaldduck/testrepo_upstream")

    expected_output = <<~STR
      2. Add testfile3 (upstream) (https://github.com/donaldduck/testrepo_upstream/pull/2)
      1. Add testfile2 (upstream) (https://github.com/donaldduck/testrepo_upstream/pull/1)
    STR
    expected_pr_numbers = [2, 1]

    actual_output = StringIO.new

    service_result = VCR.use_cassette("list_prs_upstream") do
      described_class.new(upstream_repository, out: actual_output).execute
    end

    actual_pr_numbers = service_result.map(&:number)

    expect(actual_output.string).to eql(expected_output)
    expect(actual_pr_numbers).to eql(expected_pr_numbers)
  end
end
