# frozen_string_literal: true

require 'spec_helper'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/list_milestones'

describe Geet::Services::ListMilestones do
  let(:git_client) { Geet::Utils::GitClient.new }
  let(:repository) { Geet::Git::Repository.new(git_client: git_client) }
  let(:upstream_repository) { Geet::Git::Repository.new(upstream: true, git_client: git_client) }

  it 'should list the milestones' do
    allow(git_client).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/geet')

    expected_output = <<~STR
      Finding milestones...
      Finding issues and PRs...

      5. 0.4.0
        123. Increase scope of functional testing (https://github.com/donaldduck/geet/issues/123)
        117. Add PRs/issues paging (don't show all) (https://github.com/donaldduck/geet/issues/117)
        67. Review merge AbstractIssue.list with Issue.list (https://github.com/donaldduck/geet/issues/67)
        52. Don't autoopen browser (https://github.com/donaldduck/geet/issues/52)
      14. 0.3.8
        136. Remove module namespaces where possible (https://github.com/donaldduck/geet/issues/136)
        127. Add option for including description in issues list (https://github.com/donaldduck/geet/issues/127)
        116. Add `none`/`*` assignee options to the issues listing, on manual selection (https://github.com/donaldduck/geet/issues/116)
        115. When attributes are passed via string selection, don't search the options where possible (https://github.com/donaldduck/geet/issues/115)
        110. Review help (in README) (https://github.com/donaldduck/geet/issues/110)
        109. Review gemspec (https://github.com/donaldduck/geet/issues/109)
        105. Automate branch handling on PR merging (https://github.com/donaldduck/geet/issues/105)
        81. Prompt for location vs. upstream action should be asked before editing (https://github.com/donaldduck/geet/issues/81)
        16. Implement issue/pr opening (https://github.com/donaldduck/geet/issues/16)
      19. 0.3.7 (GitLab edition)
    STR
    expected_milestone_numbers = [5, 14, 19]

    actual_output = StringIO.new

    service_result = VCR.use_cassette('list_milestones') do
      described_class.new(repository, out: actual_output).execute
    end

    actual_milestone_numbers = service_result.map(&:number)

    expect(actual_output.string).to eql(expected_output)
    expect(actual_milestone_numbers).to eql(expected_milestone_numbers)
  end

  it 'should list the upstream milestones' do
    allow(git_client).to receive(:remote).with('origin').and_return('git@github.com:donald-fr/testrepo_downstream')
    allow(git_client).to receive(:remote).with('upstream').and_return('git@github.com:donaldduck/testrepo_upstream')

    expected_output = <<~STR
      Finding milestones...
      Finding issues and PRs...

      2. Upstream milestone 2
        5. Issue upstream 3 (https://github.com/donaldduck/testrepo_upstream/issues/5)
        4. Issue upstream 2 (https://github.com/donaldduck/testrepo_upstream/issues/4)
      1. Upstream milestone 1 (due 2019-04-10)
        3. Issue upstream 1 (https://github.com/donaldduck/testrepo_upstream/issues/3)
    STR
    expected_milestone_numbers = [2, 1]

    actual_output = StringIO.new

    service_result = VCR.use_cassette('list_milestones_upstream') do
      described_class.new(upstream_repository, out: actual_output).execute
    end

    actual_milestone_numbers = service_result.map(&:number)

    expect(actual_output.string).to eql(expected_output)
    expect(actual_milestone_numbers).to eql(expected_milestone_numbers)
  end
end
