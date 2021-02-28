# frozen_string_literal: true

require 'spec_helper'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/create_milestone'

describe Geet::Services::CreateMilestone do
  let(:git_client) { Geet::Utils::GitClient.new }
  let(:repository) { Geet::Git::Repository.new(git_client: git_client) }
  let(:upstream_repository) { Geet::Git::Repository.new(upstream: true, git_client: git_client) }

  context 'with github.com' do
    it 'should create a milestone' do
      allow(git_client).to receive(:remote).with(no_args).and_return('git@github.com:donaldduck/testrepo_upstream')

      expected_output = <<~STR
        Creating milestone...
      STR

      actual_output = StringIO.new

      actual_created_label = VCR.use_cassette('github_com/create_milestone') do
        described_class.new(repository, out: actual_output).execute('my_milestone')
      end

      expect(actual_output.string).to eql(expected_output)

      expect(actual_created_label.number).to eql(6)
      expect(actual_created_label.title).to eql('my_milestone')
      expect(actual_created_label.due_on).to be(nil)
    end
  end # context 'with github.com'
end # describe Geet::Services::CreateLabel
