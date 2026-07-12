# Repository creation design

## Goal

Add `geet repo create` to create a GitHub repository from the current local Git repository, configure remotes, push the current branch, and make that branch the GitHub default branch.

## Command

```text
geet repo create [-v|--visibility private|public] [-u|--upstream ADDRESS]
```

The repository name is the basename of the current directory.

Without `--upstream`, `--visibility` selects a private or public repository. If it is omitted, Geet prompts the user to choose between `private` and `public`.

With `--upstream`, Geet creates a GitHub fork. GitHub determines the fork visibility, so Geet does not prompt for visibility and rejects an explicitly passed `--visibility`. `ADDRESS` may use any GitHub clone-address format Geet can resolve. Geet preserves the supplied address unchanged when configuring the local `upstream` remote.

## Architecture

The command decoder registers `repo.create`, and the launcher dispatches it without constructing `Git::Repository`, which assumes an existing `origin`.

`Services::CreateRepo` coordinates the complete workflow. A GitHub repository API object performs authenticated-user lookup, repository or fork creation, fork availability checks, and default-branch updates. `Utils::GitClient` exposes the local Git operations required by the service.

## Workflow

Before changing local or remote state, the service verifies that the current directory is a Git repository with a named branch and at least one commit. It fails if `origin` exists. In fork mode, it also fails if `upstream` exists. It validates visibility and the incompatibility between `--visibility` and `--upstream` during this preflight.

Normal mode creates a repository for the authenticated GitHub user with the selected visibility. Fork mode extracts the upstream repository path, requests a fork named after the current directory, and waits until GitHub makes the asynchronous fork available.

The service adds the created repository as `origin` using `git@github.com:OWNER/REPOSITORY.git`. In fork mode, it also adds the supplied address as `upstream`. It pushes the current branch to `origin` with upstream tracking, then updates the GitHub repository's default branch to the pushed branch.

On success, the command prints the created repository address and confirms the pushed default branch.

## Failure handling

Preflight failures occur before GitHub repository creation. GitHub API and Git command errors retain their existing messages and stop the workflow immediately.

If a step after repository creation fails, Geet does not delete the GitHub repository or remove configured remotes. The retained state allows manual correction without destructive rollback.

## Testing

Tests cover command decoding and dispatch, prompted and explicit visibility, invalid visibility, the `--upstream` and `--visibility` conflict, existing remotes, normal creation, asynchronous fork creation, GitHub address parsing, remote configuration, pushing with upstream tracking, default-branch updates, success output, and stopping after failures.
