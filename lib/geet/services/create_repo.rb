# frozen_string_literal: true
# typed: strict

require "stringio"
require "tty-prompt"

module Geet
  module Services
    class CreateRepo
      extend T::Sig

      VISIBILITIES = T.let(["private", "public"].freeze, T::Array[String])
      FORK_ATTEMPTS = 30
      FORK_RETRY_DELAY = 1

      sig {
        params(
          directory: String,
          out: T.any(IO, StringIO),
          git_client: Utils::GitClient,
          api_interface: T.nilable(Github::ApiInterface),
          prompt: TTY::Prompt,
          sleeper: T.proc.params(delay: Integer).void,
          fork_attempts: Integer
        ).void
      }
      def initialize(directory: Dir.pwd, out: $stdout, git_client: Utils::GitClient.new, api_interface: nil, prompt: TTY::Prompt.new, sleeper: Kernel.method(:sleep), fork_attempts: FORK_ATTEMPTS)
        @directory = directory
        @out = out
        @git_client = git_client
        @api_interface = api_interface || Github::ApiInterface.new(ENV["GH_TOKEN"] || raise("GH_TOKEN not set!"))
        @prompt = prompt
        @sleeper = sleeper
        @fork_attempts = fork_attempts
      end

      sig { params(visibility: T.nilable(String), upstream: T.nilable(String)).returns(Github::Repository) }
      def execute(visibility: nil, upstream: nil)
        preflight(visibility:, upstream:)

        name = File.basename(@directory)
        branch = @git_client.current_branch
        selected_visibility = visibility || @prompt.select("Visibility:", VISIBILITIES) if !upstream
        repository = upstream ? create_fork(name, upstream) : Github::Repository.create(name, T.must(selected_visibility), @api_interface)

        @git_client.add_remote(Utils::GitClient::ORIGIN_NAME, repository.ssh_url)
        @git_client.add_remote(Utils::GitClient::UPSTREAM_NAME, upstream) if upstream
        @git_client.push(remote_branch: branch)
        repository.update_default_branch(branch)
        @out.puts "Repository address: #{repository.html_url}"
        @out.puts "Default branch: #{branch}"
        repository
      end

      private

      sig { params(name: String, upstream: String).returns(Github::Repository) }
      def create_fork(name, upstream)
        upstream_path = @git_client.remote_path(upstream)
        provisional_repository = Github::Repository.fork(upstream_path, name, @api_interface)
        wait_for_fork(provisional_repository.full_name)
      end

      sig { params(full_name: String).returns(Github::Repository) }
      def wait_for_fork(full_name)
        @fork_attempts.times do |attempt|
          begin
            return Github::Repository.fetch(full_name, @api_interface)
          rescue Shared::HttpError => error
            raise if error.code != 404
            @sleeper.call(FORK_RETRY_DELAY) if attempt < @fork_attempts - 1
          end
        end

        raise "Timed out waiting for fork #{full_name}"
      end

      sig { params(visibility: T.nilable(String), upstream: T.nilable(String)).void }
      def preflight(visibility:, upstream:)
        validate_commits
        validate_remotes(upstream)
        validate_visibility(visibility, upstream)
      end

      sig { void }
      def validate_commits
        raise "The repository has no commits!" if !@git_client.head_commit?
      end

      sig { params(upstream: T.nilable(String)).void }
      def validate_remotes(upstream)
        raise 'Remote "origin" already exists!' if @git_client.remote_defined?(Utils::GitClient::ORIGIN_NAME)
        raise 'Remote "upstream" already exists!' if upstream && @git_client.remote_defined?(Utils::GitClient::UPSTREAM_NAME)
      end

      sig { params(visibility: T.nilable(String), upstream: T.nilable(String)).void }
      def validate_visibility(visibility, upstream)
        raise "Visibility can't be specified with upstream!" if visibility && upstream
        raise "Visibility must be private or public!" if visibility && !VISIBILITIES.include?(visibility)
      end
    end
  end
end
