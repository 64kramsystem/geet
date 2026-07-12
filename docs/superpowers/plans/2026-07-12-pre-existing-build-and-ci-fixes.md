# Pre-existing Build and CI Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align CI with the project's `GH_TOKEN` contract and expose Bundler's standard gem build tasks through Rake.

**Architecture:** Correct the existing configuration at its two sources: the CI environment declaration and the Rake task imports. Preserve the application's established token interface and use Bundler's provided gem tasks without custom wrappers.

**Tech Stack:** Ruby 4.0.5, Rake, Bundler, GitHub Actions, RSpec, Sorbet, RuboCop

## Global Constraints

- CI supplies the token as `GH_TOKEN`.
- `Rakefile` loads `bundler/gem_tasks`.
- Do not add token aliases, fallback credentials, dependency updates, or unrelated build changes.

---

### Task 1: Correct the CI token and Rake gem tasks

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `Rakefile`

**Interfaces:**
- Consumes: the application's established `GH_TOKEN` environment-variable contract and Bundler's `gem_tasks` API
- Produces: a CI test job that satisfies the test harness and standard `rake build` and release tasks

- [ ] **Step 1: Demonstrate both pre-existing failures**

Run:

```bash
env -u GH_TOKEN GITHUB_API_TOKEN=foo bundle exec rspec \
  && exit 1 \
  || test "$?" -eq 1
bundle exec rake build
```

Expected: RSpec fails because `GH_TOKEN` is absent, and Rake fails with `Don't know how to build task 'build'`.

- [ ] **Step 2: Correct the configuration**

In `.github/workflows/ci.yml`, set the test-suite environment to:

```yaml
env:
  GH_TOKEN: foo
```

At the beginning of `Rakefile`, add:

```ruby
require "bundler/gem_tasks"
```

- [ ] **Step 3: Run focused verification**

Run:

```bash
GH_TOKEN=foo bundle exec rspec \
  && bundle exec rake build
```

Expected: 39 examples pass with no failures, and `pkg/geet-0.30.1.gem` is built.

- [ ] **Step 4: Run full verification and clean generated output**

Run:

```bash
GH_TOKEN=foo bundle exec rake \
  && bundle exec srb typecheck \
  && bundle exec rubocop \
  && rm -f pkg/geet-0.30.1.gem \
  && rmdir pkg \
  && git diff --check \
  && git status --short
```

Expected: the default Rake task passes 39 examples, Sorbet reports no errors, RuboCop reports no offenses, generated packaging output is removed, and only `.github/workflows/ci.yml` and `Rakefile` are modified.

- [ ] **Step 5: Commit the fixes**

```bash
git add .github/workflows/ci.yml Rakefile \
  && git commit -m "Fix CI token and gem build tasks"
```
