# Repository Creation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `geet repo create` to create or fork a GitHub repository from the current directory, configure remotes, push the current branch, and make it the default branch.

**Architecture:** A new `Services::CreateRepo` owns the workflow without constructing `Git::Repository`. A focused `Github::Repository` models repository API operations, while `Utils::GitClient` provides the two missing local queries. The existing command decoder and launcher expose the service.

**Tech Stack:** Ruby 4.0, Sorbet runtime signatures, RSpec, WebMock/VCR-compatible GitHub REST calls, TTY::Prompt, Git CLI.

## Global Constraints

- Work only in `/home/saverio/code/geet-repo-create` on branch `repo-create`.
- The repository name is the basename of the current directory.
- Generate `origin` as `git@github.com:OWNER/REPOSITORY.git`.
- Preserve the supplied `--upstream` address unchanged for the local `upstream` remote.
- Reject an existing `origin`; in fork mode also reject an existing `upstream`.
- Reject `--visibility` with `--upstream`; otherwise accept only `private` or `public` and prompt when omitted.
- Push the current branch with upstream tracking before setting it as GitHub's default branch.
- Do not roll back a created GitHub repository or configured remote after a later failure.
- Run RSpec with `GH_TOKEN=test` so recorded integration tests can initialize their API clients.
- Do not use conventional-commit prefixes in commit titles.

---

### Task 1: GitHub repository API object

**Files:**
- Create: `lib/geet/github/repository.rb`
- Create: `spec/unit/github/repository_spec.rb`

**Interfaces:**
- Consumes: `Geet::Github::ApiInterface#send_request(api_path, data:, http_method:)`.
- Produces: `Github::Repository.create(name, visibility, api_interface)`, `.fork(upstream_path, name, api_interface)`, `.fetch(path, api_interface)`, and `#update_default_branch(branch)`; instances expose `full_name`, `html_url`, and `ssh_url`.

- [ ] **Step 1: Write failing API-object specs**

Create `spec/unit/github/repository_spec.rb` with examples that use an `instance_double(Geet::Github::ApiInterface)` and assert these exact requests and results:

```ruby
# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Geet::Github::Repository do
  let(:api_interface) { instance_double(Geet::Github::ApiInterface) }
  let(:response) do
    {
      "full_name" => "donald/geet",
      "html_url" => "https://github.com/donald/geet",
      "ssh_url" => "git@github.com:donald/geet.git",
    }
  end

  it "creates a private repository for the authenticated user" do
    expect(api_interface).to receive(:send_request).with("/user/repos", data: {name: "geet", private: true}).and_return(response)
    repository = described_class.create("geet", "private", api_interface)
    expect([repository.full_name, repository.html_url, repository.ssh_url]).to eq(["donald/geet", "https://github.com/donald/geet", "git@github.com:donald/geet.git"])
  end

  it "creates a public repository for the authenticated user" do
    expect(api_interface).to receive(:send_request).with("/user/repos", data: {name: "geet", private: false}).and_return(response)
    described_class.create("geet", "public", api_interface)
  end

  it "requests a named fork" do
    expect(api_interface).to receive(:send_request).with("/repos/upstream/project/forks", data: {name: "geet"}).and_return(response)
    described_class.fork("upstream/project", "geet", api_interface)
  end

  it "fetches a repository" do
    expect(api_interface).to receive(:send_request).with("/repos/donald/geet").and_return(response)
    expect(described_class.fetch("donald/geet", api_interface).full_name).to eq("donald/geet")
  end

  it "updates the default branch" do
    expect(api_interface).to receive(:send_request).with("/repos/donald/geet", data: {default_branch: "topic"}, http_method: :patch)
    described_class.new(response, api_interface).update_default_branch("topic")
  end
end
```

- [ ] **Step 2: Run the specs and verify the missing constant failure**

Run: `GH_TOKEN=test bundle exec rspec spec/unit/github/repository_spec.rb`

Expected: failure because `Geet::Github::Repository` is not defined.

- [ ] **Step 3: Implement the repository API object**

Create `lib/geet/github/repository.rb` with strict Sorbet signatures, readers for the three response strings, a constructor that extracts them with `fetch`, the three class methods using the exact API paths above, and:

```ruby
sig { params(branch: String).void }
def update_default_branch(branch)
  @api_interface.send_request("/repos/#{@full_name}", data: {default_branch: branch}, http_method: :patch)
end
```

Use a private `from_response` class helper so `create`, `fork`, and `fetch` each cast the response once and construct the object without duplicating extraction logic.

- [ ] **Step 4: Run the API-object specs**

Run: `GH_TOKEN=test bundle exec rspec spec/unit/github/repository_spec.rb`

Expected: 5 examples, 0 failures.

- [ ] **Step 5: Commit the API object**

```bash
git add lib/geet/github/repository.rb spec/unit/github/repository_spec.rb
git commit -m "Add GitHub repository API operations"
```

### Task 2: Local Git preflight queries and address parsing

**Files:**
- Modify: `lib/geet/utils/git_client.rb`
- Create: `spec/unit/utils/git_client_spec.rb`

**Interfaces:**
- Consumes: `Utils::GitClient#execute_git_command` and the existing `REMOTE_URL_REGEX`.
- Produces: `Utils::GitClient#head_commit? -> T::Boolean` and `#remote_path(remote_url: String) -> String`.

- [ ] **Step 1: Write failing GitClient specs**

Create `spec/unit/utils/git_client_spec.rb`. Instantiate `GitClient`, stub its private `execute_git_command`, and cover:

```ruby
describe "#head_commit?" do
  it "returns true when HEAD resolves" do
    allow(subject).to receive(:execute_git_command).with("rev-parse --verify HEAD", allow_error: true, silent_stderr: true).and_return("abc123")
    expect(subject.head_commit?).to be(true)
  end

  it "returns false for an unborn HEAD" do
    allow(subject).to receive(:execute_git_command).with("rev-parse --verify HEAD", allow_error: true, silent_stderr: true).and_return("")
    expect(subject.head_commit?).to be(false)
  end
end

describe "#remote_path" do
  it "extracts an SSH repository path" do
    expect(subject.remote_path("git@github.com:owner/project.git")).to eq("owner/project")
  end

  it "extracts an HTTPS repository path" do
    expect(subject.remote_path("https://github.com/owner/project.git")).to eq("owner/project")
  end

  it "rejects an unsupported address" do
    expect { subject.remote_path("owner/project") }.to raise_error(RuntimeError, 'Unexpected remote reference format: "owner/project"')
  end
end
```

- [ ] **Step 2: Run the specs and verify missing-method failures**

Run: `GH_TOKEN=test bundle exec rspec spec/unit/utils/git_client_spec.rb`

Expected: failures reporting undefined `head_commit?` and `remote_path`.

- [ ] **Step 3: Implement the two queries and reuse address parsing**

Add:

```ruby
sig { returns(T::Boolean) }
def head_commit?
  execute_git_command("rev-parse --verify HEAD", allow_error: true, silent_stderr: true) != ""
end

sig { params(remote_url: String).returns(String) }
def remote_path(remote_url)
  match = remote_url.match(REMOTE_URL_REGEX)
  raise "Unexpected remote reference format: #{remote_url.inspect}" if !match
  T.must(match[4])
end
```

Change `#path` to call `remote_path(remote(**remote_name_option))`, and change `#remote` to validate by calling `remote_path(remote_url)` after the existing missing-remote check. Do not expand the accepted URL grammar in this task.

- [ ] **Step 4: Run focused and full tests**

Run: `GH_TOKEN=test bundle exec rspec spec/unit/utils/git_client_spec.rb spec/integration/open_repo_spec.rb`

Expected: 7 examples, 0 failures.

Run: `GH_TOKEN=test bundle exec rake`

Expected: all examples pass.

- [ ] **Step 5: Commit the Git primitives**

```bash
git add lib/geet/utils/git_client.rb spec/unit/utils/git_client_spec.rb
git commit -m "Add repository creation Git queries"
```

### Task 3: Repository creation workflow

**Files:**
- Create: `lib/geet/services/create_repo.rb`
- Create: `spec/unit/services/create_repo_spec.rb`

**Interfaces:**
- Consumes: Task 1's `Github::Repository` methods; Task 2's `GitClient#head_commit?` and `#remote_path`; existing `#current_branch`, `#remote_defined?`, `#add_remote`, and `#push`.
- Produces: `Services::CreateRepo#execute(visibility: T.nilable(String), upstream: T.nilable(String)) -> Github::Repository`.

- [ ] **Step 1: Write failing preflight and visibility specs**

Build `spec/unit/services/create_repo_spec.rb` around doubles for `GitClient`, `Github::ApiInterface`, and `TTY::Prompt`. Construct the service with injectable `directory: "/tmp/geet"`, `out: StringIO.new`, `git_client:`, `api_interface:`, `prompt:`, `sleeper: ->(_) {}` and `fork_attempts: 3`.

Add examples asserting that no API request occurs and the exact errors are raised for:

```ruby
"The repository has no commits!"
"Remote \"origin\" already exists!"
"Remote \"upstream\" already exists!"
"Visibility must be private or public!"
"Visibility can't be specified with upstream!"
```

The common valid preflight stubs are `head_commit? => true`, `current_branch => "topic"`, `remote_defined?("origin") => false`, and, only in fork mode, `remote_defined?("upstream") => false`.

Add one example where `visibility` is nil, `prompt.select("Visibility:", ["private", "public"])` returns `"private"`, and the normal create path receives `"private"`. Add one example showing explicit `"public"` does not call the prompt.

- [ ] **Step 2: Run the preflight specs and verify the missing service failure**

Run: `GH_TOKEN=test bundle exec rspec spec/unit/services/create_repo_spec.rb`

Expected: failure because `Geet::Services::CreateRepo` is not defined.

- [ ] **Step 3: Implement initialization and preflight**

Create the strict service with these defaults and injected types:

```ruby
VISIBILITIES = T.let(["private", "public"].freeze, T::Array[String])
FORK_ATTEMPTS = 30
FORK_RETRY_DELAY = 1

def initialize(directory: Dir.pwd, out: $stdout, git_client: Utils::GitClient.new, api_interface: nil, prompt: TTY::Prompt.new, sleeper: Kernel.method(:sleep), fork_attempts: FORK_ATTEMPTS)
  @directory = directory
  @out = out
  @git_client = git_client
  @api_interface = api_interface || Github::ApiInterface.new(ENV["GH_TOKEN"] || raise("GH_TOKEN not set!"))
  @prompt = prompt
  @sleeper = sleeper
  @fork_attempts = fork_attempts
end
```

`execute` must call preflight before prompting or making API calls. Derive `name = File.basename(@directory)` and `branch = @git_client.current_branch`. Keep validation in short private methods with the exact error text from Step 1.

- [ ] **Step 4: Run preflight specs**

Run: `GH_TOKEN=test bundle exec rspec spec/unit/services/create_repo_spec.rb`

Expected: all preflight and prompt examples pass; workflow examples added next are still absent.

- [ ] **Step 5: Add failing normal-workflow and fork-workflow specs**

For normal creation, stub `Github::Repository.create("geet", "private", api_interface)` to return a repository double with `full_name: "donald/geet"`, `ssh_url: "git@github.com:donald/geet.git"`, and `html_url: "https://github.com/donald/geet"`. Assert ordered calls to add `origin`, push `"topic"`, and update the default branch.

For fork creation, use upstream `https://github.com/upstream/project.git`, assert `remote_path` returns `"upstream/project"`, assert `Github::Repository.fork("upstream/project", "geet", api_interface)` returns a provisional repository with `full_name: "donald/geet"`, then make `.fetch("donald/geet", api_interface)` first raise `Shared::HttpError.new("Not Found", 404)` and then return the available repository. Assert the sleeper receives `1`, the exact supplied URL is added as `upstream`, SSH `origin` is added, and push/default-branch calls follow.

Add a timeout example where all three fetches raise 404 and expect `"Timed out waiting for fork donald/geet"`. Add a non-404 fetch error example and expect it to propagate immediately. Add a failure-order example proving an `add_remote` error prevents push and default-branch update. Assert success output contains both `Repository address: https://github.com/donald/geet` and `Default branch: topic`.

- [ ] **Step 6: Implement normal creation, fork waiting, remotes, push, and output**

Implement the workflow in this order:

```ruby
repository = upstream ? create_fork(name, upstream) : Github::Repository.create(name, selected_visibility, @api_interface)
@git_client.add_remote(Utils::GitClient::ORIGIN_NAME, repository.ssh_url)
@git_client.add_remote(Utils::GitClient::UPSTREAM_NAME, upstream) if upstream
@git_client.push(remote_branch: branch)
repository.update_default_branch(branch)
@out.puts "Repository address: #{repository.html_url}"
@out.puts "Default branch: #{branch}"
repository
```

`create_fork` parses the upstream, requests the fork, then calls `wait_for_fork(full_name)`. `wait_for_fork` attempts `Github::Repository.fetch` up to `@fork_attempts` times, rescues only `Shared::HttpError` with code 404, sleeps `FORK_RETRY_DELAY` between attempts but not after the final attempt, and raises the exact timeout error after exhaustion.

- [ ] **Step 7: Run service and full tests**

Run: `GH_TOKEN=test bundle exec rspec spec/unit/services/create_repo_spec.rb`

Expected: all examples pass.

Run: `GH_TOKEN=test bundle exec rake`

Expected: all examples pass.

- [ ] **Step 8: Commit the service**

```bash
git add lib/geet/services/create_repo.rb spec/unit/services/create_repo_spec.rb
git commit -m "Add repository creation workflow"
```

### Task 4: CLI integration and user documentation

**Files:**
- Modify: `lib/geet/commandline/commands.rb`
- Modify: `lib/geet/commandline/configuration.rb`
- Modify: `bin/geet`
- Create: `spec/unit/commandline/configuration_spec.rb`
- Create: `spec/unit/geet_launcher_spec.rb`
- Modify: `README.md`

**Interfaces:**
- Consumes: `Services::CreateRepo#execute(visibility:, upstream:)` from Task 3.
- Produces: `REPO_CREATE_COMMAND = "repo.create"` and CLI syntax `geet repo create [-v|--visibility private|public] [-u|--upstream ADDRESS]`.

- [ ] **Step 1: Write failing command-decoding specs**

In `spec/unit/commandline/configuration_spec.rb`, stub `ARGV` via `stub_const("ARGV", [...])` and assert:

```ruby
expect(described_class.new.decode_argv).to eq(["repo.create", {visibility: "private", upstream: "git@github.com:owner/project.git"}])
```

Cover long options and a second example for `-v public -u https://github.com/owner/project.git` so both aliases and value parsing are exercised.

- [ ] **Step 2: Run the decoder specs and verify failure**

Run: `GH_TOKEN=test bundle exec rspec spec/unit/commandline/configuration_spec.rb`

Expected: decoding fails because `repo.create` is not registered.

- [ ] **Step 3: Register the command and options**

Add `REPO_CREATE_COMMAND = T.let("repo.create", String)`, define:

```ruby
REPO_CREATE_OPTIONS = T.let([
  ["-v", "--visibility private|public", "Repository visibility"],
  ["-u", "--upstream address", "Create a fork of this repository"],
  long_help: "Create a GitHub repository from the current directory.",
], T::Array[T.any(T::Hash[T.untyped, T.untyped], T::Array[String])])
```

and register `"create" => REPO_CREATE_OPTIONS` under `"repo"`.

- [ ] **Step 4: Run the decoder specs**

Run: `GH_TOKEN=test bundle exec rspec spec/unit/commandline/configuration_spec.rb`

Expected: 2 examples, 0 failures.

- [ ] **Step 5: Write a failing launcher dispatch spec**

Change the final line of `bin/geet` to `GeetLauncher.new.launch if $PROGRAM_NAME == __FILE__` so the class can be required safely. In `spec/unit/geet_launcher_spec.rb`, require `../../bin/geet`, stub `Commandline::Configuration#decode_argv` to return `[REPO_CREATE_COMMAND, {visibility: "private"}]`, expect `Services::CreateRepo.new.execute(visibility: "private")`, and expect `Git::Repository` not to receive `new`. This proves creation bypasses the existing-origin abstraction.

- [ ] **Step 6: Run the launcher spec and verify dispatch failure**

Run: `GH_TOKEN=test bundle exec rspec spec/unit/geet_launcher_spec.rb`

Expected: failure because the launcher does not handle `REPO_CREATE_COMMAND`.

- [ ] **Step 7: Add early launcher dispatch**

Immediately after decoding arguments, add:

```ruby
if command == REPO_CREATE_COMMAND
  Services::CreateRepo.new.execute(**options)
  return
end
```

Leave existing commands and repository construction unchanged below this early return.

- [ ] **Step 8: Document repository creation**

Add repository creation and forking to the supported operations. Add concise samples showing interactive visibility, `--visibility private`, and `--upstream git@github.com:owner/project.git`, plus the effects: SSH `origin`, preserved `upstream`, pushed current branch, and default-branch update.

- [ ] **Step 9: Run CLI, type, style, and full test verification**

Run: `GH_TOKEN=test bundle exec rspec spec/unit/commandline/configuration_spec.rb spec/unit/geet_launcher_spec.rb`

Expected: all examples pass.

Run: `GH_TOKEN=test bundle exec rake`

Expected: all examples pass.

Run: `bundle exec srb tc`

Expected: `No errors! Great job.`

Run: `bundle exec rubocop`

Expected: no offenses.

Run: `git diff --check`

Expected: no output and exit status 0.

- [ ] **Step 10: Commit CLI integration and documentation**

```bash
git add lib/geet/commandline/commands.rb lib/geet/commandline/configuration.rb bin/geet spec/unit/commandline/configuration_spec.rb spec/unit/geet_launcher_spec.rb README.md
git commit -m "Expose repository creation command"
```

### Task 5: Final verification

**Files:**
- Verify only; modify files only to correct failures caused by this feature.

**Interfaces:**
- Consumes: all previous tasks.
- Produces: a clean, verified `repo-create` branch.

- [ ] **Step 1: Run the complete verification suite from a clean shell command**

```bash
GH_TOKEN=test bundle exec rake
bundle exec srb tc
bundle exec rubocop
git diff --check
git status --short --branch
```

Expected: all tests pass, Sorbet reports no errors, RuboCop reports no offenses, diff check is silent, and status shows `## repo-create` with no changed files.

- [ ] **Step 2: Review the commit series**

Run: `git log --oneline master..HEAD`

Expected: the design commit followed by conceptually atomic API, Git primitive, service, and CLI commits.
