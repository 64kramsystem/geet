require 'spec_helper'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/create_label'

describe Geet::Services::CreateLabel do
  let(:repository) { Geet::Git::Repository.new }

  context 'with user-specified color' do
    it 'should create a label' do
      allow(repository).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo')

      expected_output = <<~STR
        Creating label...
        Created with color #c64c64
      STR

      actual_output = StringIO.new

      actual_created_label = VCR.use_cassette("create_label") do
        described_class.new.execute(repository, 'my_label', color: 'c64c64', output: actual_output)
      end

      expect(actual_output.string).to eql(expected_output)

      expect(actual_created_label.name).to eql('my_label')
      expect(actual_created_label.color).to eql('c64c64')
    end
  end

  context 'with auto-generated color' do
    it 'should create a label' do
      # allow(repository).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo')

      expected_output_template = <<~STR
        Creating label...
        Created with color #%s
      STR

      actual_output = StringIO.new

      actual_created_label = VCR.use_cassette("create_label_with_random_color") do
        described_class.new.execute(repository, 'my_label', output: actual_output)
      end

      expected_output = expected_output_template % actual_created_label.color

      expect(actual_output.string).to eql(expected_output)

      expect(actual_created_label.name).to eql('my_label')
      expect(actual_created_label.color).to match(/\A[0-9a-f]{6}\z/)
    end
  end
end
