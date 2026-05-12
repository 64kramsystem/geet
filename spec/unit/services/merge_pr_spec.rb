# frozen_string_literal: true
# typed: false

require "spec_helper"

require_relative "../../../lib/geet/git/repository"
require_relative "../../../lib/geet/services/merge_pr"

describe Geet::Services::MergePr do
  describe "#execute" do
    let(:repository) { instance_double(Geet::Git::Repository) }
    let(:git_client) { instance_double(Geet::Utils::GitClient) }

    subject { described_class.new(repository, out: StringIO.new, git_client: git_client) }

    it "raises when both --rebase and --squash are passed" do
      expect { subject.execute(rebase: true, squash: true) }
        .to raise_error("Can't specify both --rebase and --squash")
    end
  end
end
