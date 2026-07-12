# Final fixes report

## Scope and review evaluation

- Fixed the critical shell-injection finding in `Geet::Utils::GitClient#add_remote` by applying `Shellwords#shellescape` to the remote URL, matching the existing treatment of the remote name and ensuring the URL reaches `git remote add` as one argument.
- Added a detached-HEAD ordering regression. The existing service behavior already calls `current_branch` before visibility prompting and repository API creation, so no production change was required.
- Evaluated non-Git directory behavior. `GitClient#head_commit?` invokes `git rev-parse --verify HEAD` with `allow_error: true` and `silent_stderr: true`, converting a non-repository failure to `false`; `CreateRepo#validate_commits` therefore fails with `The repository has no commits!` before prompt/API work. No additional guard was added because it would duplicate the established observable behavior without a distinct requirement.
- Used one temporary-repository regression for the critical fix. It is an integration-style unit spec that invokes real `git`, proves shell metacharacters do not execute, and proves the complete URL is stored verbatim. A separate redundant integration spec was not added.

## RED evidence

After adding the temporary-repository and detached-HEAD regressions, ran:

```text
GH_TOKEN=test bundle exec rspec spec/unit/utils/git_client_spec.rb spec/unit/services/create_repo_spec.rb
```

Result: exit 1, 19 examples, 1 failure. The `#add_remote` regression failed at `expect(File).not_to exist(marker)` because the vulnerable command executed `touch` and created the marker. This directly demonstrated the reported injection vulnerability. The detached-HEAD regression passed, confirming the requested ordering was existing behavior.

## GREEN evidence

Changed only the URL interpolation in `#add_remote` from `#{url}` to `#{url.shellescape}`, then reran:

```text
GH_TOKEN=test bundle exec rspec spec/unit/utils/git_client_spec.rb spec/unit/services/create_repo_spec.rb
```

Result: exit 0, 19 examples, 0 failures. The test additionally verifies `git remote get-url origin` returns the original URL including `; touch ...`, proving it was passed as one literal argument rather than sanitized by truncation.

## Final verification

All commands were run from `/home/saverio/code/geet-repo-create` after the implementation change:

- `GH_TOKEN=test bundle exec rake` — exit 0; 66 examples, 0 failures (random seed 51014).
- `bundle exec srb tc` — exit 0; `No errors!`.
- `bundle exec rubocop` — exit 0; 70 files inspected, no offenses.
- `git diff --check` — exit 0; no whitespace errors.
- Diff review showed only the intended one-line production fix, the two regressions, and this report.
