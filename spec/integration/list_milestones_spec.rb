# frozen_string_literal: true

require 'spec_helper'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/list_milestones'

describe Geet::Services::ListMilestones do
  let(:git_client) { Geet::Utils::GitClient.new }
  let(:repository) { Geet::Git::Repository.new(git_client: git_client) }

  it 'should list the milestones' do
    allow(git_client).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/geet')

    expected_output = <<~STR
      Finding milestones...
      Finding issues...

      6. 0.2.1
        51. Services should take repository in the initializer (https://github.com/donaldduck/geet/issues/51)
        49. Add issue list --assigned (https://github.com/donaldduck/geet/issues/49)
        29. Edit Issue/PR properties in a single request after creation (https://github.com/donaldduck/geet/issues/29)
      8. 0.2.3
        16. Implement issue opening (https://github.com/donaldduck/geet/issues/16)
      7. 0.2.2
        43. PR Merging: add support for upstream and branch autodelete (https://github.com/donaldduck/geet/issues/43)
        35. Improve design of repository-independent actions (https://github.com/donaldduck/geet/issues/35)
      5. 0.3.0
        4. Allow writing description in an editor (https://github.com/donaldduck/geet/issues/4)
      4. 0.2.0
        41. Add test suites (https://github.com/donaldduck/geet/issues/41)
    STR
    expected_milestone_numbers = [6, 8, 7, 5, 4]

    actual_output = StringIO.new

    service_result = VCR.use_cassette('list_milestones') do
      described_class.new.execute(repository, output: actual_output)
    end

    actual_milestone_numbers = service_result.map(&:number)

    expect(actual_output.string).to eql(expected_output)
    expect(actual_milestone_numbers).to eql(expected_milestone_numbers)
  end
end
