require 'spec_helper'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/list_labels'

describe Geet::Services::ListLabels do
  let(:repository) { Geet::Git::Repository.new }

  context 'with github.com' do
    it 'should list the labels' do
      allow(repository).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/geet')

      expected_output = <<~STR
        - bug
        - enhancement
        - technical_debt
        - top_priority
      STR
      expected_labels = %w[bug enhancement technical_debt top_priority]

      actual_output = StringIO.new
      actual_labels = VCR.use_cassette("github.com/list_labels") do
        described_class.new.execute(repository, output: actual_output)
      end

      expect(actual_output.string).to eql(expected_output)
      expect(actual_labels).to eql(expected_labels)
    end
  end

  context 'with gitlab.com' do
    it 'should list the labels' do
      allow(repository).to receive(:remote).with('origin').and_return('git@gitlab.com:donaldduck/testproject')

      expected_output = <<~STR
        - bug
        - confirmed
        - critical
        - discussion
        - documentation
        - enhancement
        - suggestion
        - support
      STR
      expected_labels = %w[bug confirmed critical discussion documentation enhancement suggestion support]

      actual_output = StringIO.new
      actual_labels = VCR.use_cassette("gitlab.com/list_labels") do
        described_class.new.execute(repository, output: actual_output)
      end

      expect(actual_output.string).to eql(expected_output)
      expect(actual_labels).to eql(expected_labels)
    end
  end
end
