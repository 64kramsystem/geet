# frozen_string_literal: true

require 'spec_helper'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/list_issues'

describe Geet::Services::ListIssues do
  let(:repository) { Geet::Git::Repository.new }
  let(:upstream_repository) { Geet::Git::Repository.new(upstream: true) }

  context 'with github.com' do
    it 'should list the issues' do
      allow(repository).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo')

      expected_output = <<~STR
        5. Title 2 (https://github.com/donaldduck/testrepo/issues/5)
        4. Title 1 (https://github.com/donaldduck/testrepo/issues/4)
      STR
      expected_issue_numbers = [5, 4]

      actual_output = StringIO.new

      service_result = VCR.use_cassette('github_com/list_issues') do
        described_class.new.execute(repository, output: actual_output)
      end

      actual_issue_numbers = service_result.map(&:number)

      expect(actual_output.string).to eql(expected_output)
      expect(actual_issue_numbers).to eql(expected_issue_numbers)
    end

    it 'should list the upstream issues' do
      allow(upstream_repository).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo_2f')
      allow(upstream_repository).to receive(:remote).with('upstream').and_return('git@github.com:donald-fr/testrepo_u')

      expected_output = <<~STR
        2. Title 2 U (https://github.com/donald-fr/testrepo_u/issues/2)
        1. Title 1 U (https://github.com/donald-fr/testrepo_u/issues/1)
      STR
      expected_issue_numbers = [2, 1]

      actual_output = StringIO.new

      service_result = VCR.use_cassette('github_com/list_issues_upstream') do
        described_class.new.execute(upstream_repository, output: actual_output)
      end

      actual_issue_numbers = service_result.map(&:number)

      expect(actual_output.string).to eql(expected_output)
      expect(actual_issue_numbers).to eql(expected_issue_numbers)
    end
  end

  context 'with gitlab.com' do
    it 'should list the issues' do
      allow(repository).to receive(:remote).with('origin').and_return('git@gitlab.com:donaldduck/testproject')

      expected_output = <<~STR
        2. I like more pizza (https://gitlab.com/donaldduck/testproject/issues/2)
        1. I like pizza (https://gitlab.com/donaldduck/testproject/issues/1)
      STR
      expected_issue_numbers = [2, 1]

      actual_output = StringIO.new

      service_result = VCR.use_cassette('gitlab_com/list_issues') do
        described_class.new.execute(repository, output: actual_output)
      end

      actual_issue_numbers = service_result.map(&:number)

      expect(actual_output.string).to eql(expected_output)
      expect(actual_issue_numbers).to eql(expected_issue_numbers)
    end
  end
end
