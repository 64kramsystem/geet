# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/create_gist'

describe Geet::Services::CreateGist do
  let(:temp_filename) { File.join(Dir.tmpdir, 'geet_gist_test.md') }
  let(:temp_file) { File.open(temp_filename, 'w') { |file| file << 'testcontent' } }

  it 'should create a public gist' do
    expected_output = <<~STR
      Creating a public gist...
      Gist address: https://gist.github.com/b01dface
    STR

    actual_output = StringIO.new

    VCR.use_cassette('create_gist_public') do
      described_class.new(out: actual_output).execute(
        temp_file.path, description: 'testdescription', publik: true
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
      described_class.new(out: actual_output).execute(
        temp_file.path, description: 'testdescription'
      )
    end

    expect(actual_output.string).to eql(expected_output)
  end
end
