# frozen_string_literal: true

require 'spec_helper'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/merge_pr'

describe Geet::Services::MergePr do
  let(:repository) { Geet::Git::Repository.new }

  it 'should merge the PR for the current branch' do
    allow(repository).to receive(:current_branch).and_return('mybranch1')
    allow(repository).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo')

    expected_output = <<~STR
      Finding PR with head (mybranch1)...
      Merging PR #3...
    STR
    expected_pr_number = 3

    actual_output = StringIO.new

    service_result = VCR.use_cassette('merge_pr') do
      described_class.new.execute(repository, output: actual_output)
    end

    actual_pr_number = service_result.number

    expect(actual_output.string).to eql(expected_output)
    expect(actual_pr_number).to eql(expected_pr_number)
  end

  it 'should merge the PR for the current branch, with branch deletion' do
    allow(repository).to receive(:current_branch).and_return('mybranch')
    allow(repository).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo')

    expected_output = <<~STR
      Finding PR with head (mybranch)...
      Merging PR #3...
      Deleting branch mybranch...
    STR
    expected_pr_number = 3

    actual_output = StringIO.new

    service_result = VCR.use_cassette('merge_pr_with_branch_deletion') do
      described_class.new.execute(repository, delete_branch: true, output: actual_output)
    end

    actual_pr_number = service_result.number

    expect(actual_output.string).to eql(expected_output)
    expect(actual_pr_number).to eql(expected_pr_number)
  end
end
