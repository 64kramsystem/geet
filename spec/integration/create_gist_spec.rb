# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/create_gist'

describe Geet::Services::CreateGist do
  let(:repository) { Geet::Git::Repository.new }
  let(:tempfile) { Tempfile.open('geet_gist') { |file| file << 'testcontent' } }

  it 'should create a public gist' do
    expected_output = <<~STR
      Creating a public gist...
      Gist address: https://gist.github.com/b01dface
    STR

    actual_output = StringIO.new

    VCR.use_cassette('create_gist_public') do
      described_class.new.execute(
        repository, tempfile.path,
        description: 'testdescription', publik: true, no_browse: true, output: actual_output
      )
    end

    expect(actual_output.string).to eql(expected_output)
  end

  it 'should create a private gist' do
    expected_output = <<~STR
      Creating a private gist...
      Gist address: https://gist.github.com/deadbeef
    STR

    actual_output = StringIO.new

    VCR.use_cassette('create_gist_private') do
      described_class.new.execute(
        repository, tempfile.path,
        description: 'testdescription', no_browse: true, output: actual_output
      )
    end

    expect(actual_output.string).to eql(expected_output)
  end
end
