# frozen_string_literal: true
# typed: false

require "spec_helper"

describe Geet::Services::CreateRepo do
  describe "#execute" do
    let(:git_client) { instance_double(Geet::Utils::GitClient) }
    let(:api_interface) { instance_double(Geet::Github::ApiInterface) }
    let(:prompt) { instance_double(TTY::Prompt) }
    let(:out) { StringIO.new }

    subject(:service) do
      described_class.new(
        directory: "/tmp/geet",
        out:,
        git_client:,
        api_interface:,
        prompt:,
        sleeper: ->(_) {},
        fork_attempts: 3
      )
    end

    before do
      allow(git_client).to receive(:head_commit?).and_return(true)
      allow(git_client).to receive(:current_branch).and_return("topic")
      allow(git_client).to receive(:remote_defined?).with("origin").and_return(false)
    end

    it "rejects a repository without commits before making an API request" do
      allow(git_client).to receive(:head_commit?).and_return(false)

      expect(Geet::Github::Repository).not_to receive(:create)
      expect { service.execute(visibility: "private") }.to raise_error("The repository has no commits!")
    end

    it "rejects an existing origin before making an API request" do
      allow(git_client).to receive(:remote_defined?).with("origin").and_return(true)

      expect(Geet::Github::Repository).not_to receive(:create)
      expect { service.execute(visibility: "private") }.to raise_error('Remote "origin" already exists!')
    end

    it "rejects an existing upstream before making an API request" do
      allow(git_client).to receive(:remote_defined?).with("upstream").and_return(true)

      expect(Geet::Github::Repository).not_to receive(:fork)
      expect { service.execute(upstream: "https://github.com/upstream/project.git") }
        .to raise_error('Remote "upstream" already exists!')
    end

    it "rejects invalid visibility before making an API request" do
      expect(Geet::Github::Repository).not_to receive(:create)
      expect { service.execute(visibility: "internal") }.to raise_error("Visibility must be private or public!")
    end

    it "rejects visibility in fork mode before making an API request" do
      allow(git_client).to receive(:remote_defined?).with("upstream").and_return(false)

      expect(Geet::Github::Repository).not_to receive(:fork)
      expect { service.execute(visibility: "private", upstream: "https://github.com/upstream/project.git") }
        .to raise_error("Visibility can't be specified with upstream!")
    end

    it "prompts for visibility when it is omitted" do
      repository = instance_double(Geet::Github::Repository, ssh_url: "git@github.com:donald/geet.git", html_url: "https://github.com/donald/geet")
      allow(prompt).to receive(:select).with("Visibility:", ["private", "public"]).and_return("private")
      allow(Geet::Github::Repository).to receive(:create).with("geet", "private", api_interface).and_return(repository)
      allow(git_client).to receive(:add_remote)
      allow(git_client).to receive(:push)
      allow(repository).to receive(:update_default_branch)

      service.execute
    end

    it "does not prompt when public visibility is explicit" do
      repository = instance_double(Geet::Github::Repository, ssh_url: "git@github.com:donald/geet.git", html_url: "https://github.com/donald/geet")
      expect(prompt).not_to receive(:select)
      allow(Geet::Github::Repository).to receive(:create).with("geet", "public", api_interface).and_return(repository)
      allow(git_client).to receive(:add_remote)
      allow(git_client).to receive(:push)
      allow(repository).to receive(:update_default_branch)

      service.execute(visibility: "public")
    end

    it "creates a repository, configures origin, pushes, and updates the default branch in order" do
      repository = instance_double(
        Geet::Github::Repository,
        full_name: "donald/geet",
        ssh_url: "git@github.com:donald/geet.git",
        html_url: "https://github.com/donald/geet"
      )
      allow(prompt).to receive(:select).and_return("private")
      expect(Geet::Github::Repository).to receive(:create)
        .with("geet", "private", api_interface).ordered.and_return(repository)
      expect(git_client).to receive(:add_remote)
        .with("origin", "git@github.com:donald/geet.git").ordered
      expect(git_client).to receive(:push).with(remote_branch: "topic").ordered
      expect(repository).to receive(:update_default_branch).with("topic").ordered

      expect(service.execute).to eq(repository)
      expect(out.string).to include("Repository address: https://github.com/donald/geet")
      expect(out.string).to include("Default branch: topic")
    end

    it "waits for a fork, configures both remotes, pushes, and updates the default branch" do
      upstream = "https://github.com/upstream/project.git"
      provisional_repository = instance_double(Geet::Github::Repository, full_name: "donald/geet")
      repository = instance_double(
        Geet::Github::Repository,
        ssh_url: "git@github.com:donald/geet.git",
        html_url: "https://github.com/donald/geet"
      )
      sleeper = proc {}
      service = described_class.new(
        directory: "/tmp/geet", out:, git_client:, api_interface:, prompt:,
        sleeper:, fork_attempts: 3
      )
      allow(git_client).to receive(:remote_defined?).with("upstream").and_return(false)
      expect(git_client).to receive(:remote_path).with(upstream).ordered.and_return("upstream/project")
      expect(Geet::Github::Repository).to receive(:fork)
        .with("upstream/project", "geet", api_interface).ordered.and_return(provisional_repository)
      expect(Geet::Github::Repository).to receive(:fetch)
        .with("donald/geet", api_interface).ordered.and_raise(Geet::Shared::HttpError.new("Not Found", 404))
      expect(sleeper).to receive(:call).with(1).ordered
      expect(Geet::Github::Repository).to receive(:fetch)
        .with("donald/geet", api_interface).ordered.and_return(repository)
      expect(git_client).to receive(:add_remote)
        .with("origin", "git@github.com:donald/geet.git").ordered
      expect(git_client).to receive(:add_remote).with("upstream", upstream).ordered
      expect(git_client).to receive(:push).with(remote_branch: "topic").ordered
      expect(repository).to receive(:update_default_branch).with("topic").ordered

      expect(service.execute(upstream:)).to eq(repository)
      expect(out.string).to include("Repository address: https://github.com/donald/geet")
      expect(out.string).to include("Default branch: topic")
    end

    it "times out after all fork fetch attempts return 404" do
      upstream = "https://github.com/upstream/project.git"
      provisional_repository = instance_double(Geet::Github::Repository, full_name: "donald/geet")
      allow(git_client).to receive(:remote_defined?).with("upstream").and_return(false)
      allow(git_client).to receive(:remote_path).with(upstream).and_return("upstream/project")
      allow(Geet::Github::Repository).to receive(:fork).and_return(provisional_repository)
      allow(Geet::Github::Repository).to receive(:fetch)
        .and_raise(Geet::Shared::HttpError.new("Not Found", 404))

      expect { service.execute(upstream:) }.to raise_error("Timed out waiting for fork donald/geet")
    end

    it "immediately propagates a non-404 fork fetch error" do
      upstream = "https://github.com/upstream/project.git"
      provisional_repository = instance_double(Geet::Github::Repository, full_name: "donald/geet")
      error = Geet::Shared::HttpError.new("Server Error", 500)
      allow(git_client).to receive(:remote_defined?).with("upstream").and_return(false)
      allow(git_client).to receive(:remote_path).with(upstream).and_return("upstream/project")
      allow(Geet::Github::Repository).to receive(:fork).and_return(provisional_repository)
      allow(Geet::Github::Repository).to receive(:fetch).and_raise(error)

      expect { service.execute(upstream:) }.to raise_error(error)
    end

    it "stops before pushing or updating the default branch when adding a remote fails" do
      repository = instance_double(
        Geet::Github::Repository,
        ssh_url: "git@github.com:donald/geet.git",
        html_url: "https://github.com/donald/geet"
      )
      allow(Geet::Github::Repository).to receive(:create).and_return(repository)
      allow(git_client).to receive(:add_remote).and_raise("remote failure")
      expect(git_client).not_to receive(:push)
      expect(repository).not_to receive(:update_default_branch)

      expect { service.execute(visibility: "private") }.to raise_error("remote failure")
    end
  end
end
