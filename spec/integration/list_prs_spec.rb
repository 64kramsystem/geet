require 'spec_helper'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/list_prs'

describe Geet::Services::ListPrs do
  let(:repository) { Geet::Git::Repository.new }
  let(:upstream_repository) { Geet::Git::Repository.new(upstream: true) }

  it 'should list the PRs' do
    allow(repository).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo')

    expected_output = <<~STR
      6. Title 2 (https://github.com/donaldduck/testrepo/pull/6)
      3. Title (https://github.com/donaldduck/testrepo/pull/3)
    STR
    expected_pr_numbers = [6, 3]

    actual_output = StringIO.new

    service_result = VCR.use_cassette("list_prs") do
      described_class.new.execute(repository, output: actual_output)
    end

    actual_pr_numbers = service_result.map(&:number)

    expect(actual_output.string).to eql(expected_output)
    expect(actual_pr_numbers).to eql(expected_pr_numbers)
  end

  it 'should list the upstream PRs' do
    allow(upstream_repository).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo_2f')
    allow(upstream_repository).to receive(:remote).with('upstream').and_return('git@github.com:donald-fr/testrepo_u')

    expected_output = <<~STR
      5. Title 2 (https://github.com/donald-fr/testrepo_u/pull/5)
      4. Title (https://github.com/donald-fr/testrepo_u/pull/4)
    STR
    expected_pr_numbers = [5, 4]

    actual_output = StringIO.new

    service_result = VCR.use_cassette("list_prs_upstream") do
      described_class.new.execute(upstream_repository, output: actual_output)
    end

    actual_pr_numbers = service_result.map(&:number)

    expect(actual_output.string).to eql(expected_output)
    expect(actual_pr_numbers).to eql(expected_pr_numbers)
  end
end
