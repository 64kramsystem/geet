# frozen_string_literal: true

require 'spec_helper'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/create_label'

describe Geet::Services::CreateLabel do
  let(:git_client) { Geet::Utils::GitClient.new }
  let(:repository) { Geet::Git::Repository.new(git_client: git_client) }
  let(:upstream_repository) { Geet::Git::Repository.new(upstream: true, git_client: git_client) }

  context 'with user-specified color' do
    it 'should create a label' do
      allow(git_client).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo')

      expected_output = <<~STR
        Creating label...
        Created with color #c64c64
      STR

      actual_output = StringIO.new

      actual_created_label = VCR.use_cassette('create_label') do
        described_class.new(repository, out: actual_output).execute('my_label', color: 'c64c64')
      end

      expect(actual_output.string).to eql(expected_output)

      expect(actual_created_label.name).to eql('my_label')
      expect(actual_created_label.color).to eql('c64c64')
    end

    context 'upstream' do
      it 'should create a label' do
        allow(git_client).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo')
        allow(git_client).to receive(:remote).with('upstream').and_return('git@github.com:donaldduck-fr/testrepo_gh')

        expected_output = <<~STR
          Creating label...
          Created with color #c64c64
        STR

        actual_output = StringIO.new

        actual_created_label = VCR.use_cassette('create_label_upstream') do
          described_class.new(upstream_repository, out: actual_output).execute('my_label', color: 'c64c64')
        end

        expect(actual_output.string).to eql(expected_output)

        expect(actual_created_label.name).to eql('my_label')
        expect(actual_created_label.color).to eql('c64c64')
      end
    end
  end

  context 'with auto-generated color' do
    it 'should create a label' do
      allow(git_client).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo')

      actual_output = StringIO.new

      service_instance = described_class.new(repository, out: actual_output)

      expect(service_instance).to receive(:rand).with(2**24).and_return(38911)

      expected_output_template = <<~STR
        Creating label...
        Created with color #0097ff
      STR

      actual_created_label = VCR.use_cassette('create_label_with_random_color') do
        service_instance.execute('my_label')
      end

      expected_output = format(expected_output_template, color: actual_created_label.color)

      expect(actual_output.string).to eql(expected_output)

      expect(actual_created_label.name).to eql('my_label')
      expect(actual_created_label.color).to eql('0097ff')
    end
  end
end
