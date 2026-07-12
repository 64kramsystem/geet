# Ruby 4.0.5 Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Ruby 4.0.5 the project default while supporting Ruby 3.3 and newer.

**Architecture:** Keep the upgrade confined to the project's Ruby version declaration, gem compatibility metadata, CI matrix, and any dependency or code incompatibility demonstrated by the verification suite. Do not refresh dependencies or refactor code without a Ruby 4.0.5 failure that requires it.

**Tech Stack:** Ruby 4.0.5, Bundler 4.0.3, RSpec, Sorbet, RuboCop, GitHub Actions

## Global Constraints

- The project development Ruby version is exactly `4.0.5`.
- The gem's minimum supported Ruby version is exactly `3.3.0`.
- CI covers Ruby head, 4.0, 3.4, and 3.3.
- Dependency and source changes require a demonstrated Ruby 4.0.5 incompatibility.

---

### Task 1: Ruby support declarations and compatibility verification

**Files:**
- Modify: `.ruby-version`
- Modify: `geet.gemspec`
- Modify: `.github/workflows/ci.yml`
- Modify if required by Bundler: `Gemfile.lock`
- Modify if required by a failing check: the source or dependency declaration responsible for that failure

**Interfaces:**
- Consumes: Ruby version selection by `.ruby-version`, RubyGems metadata from `geet.gemspec`, and the GitHub Actions Ruby matrix
- Produces: a Ruby 4.0.5 development environment and a tested Ruby 3.3-or-newer compatibility contract

- [ ] **Step 1: Confirm the existing declarations have the expected old values**

Run:

```bash
test "$(< .ruby-version)" = "3.4.6" \
  && rg -n 'required_ruby_version = ">= 3\.2\.0"' geet.gemspec \
  && rg -n 'ruby-version: \[head, 4\.0, 3\.4, 3\.3, 3\.2\]' .github/workflows/ci.yml
```

Expected: exit status 0 and matches for the gemspec and CI matrix.

- [ ] **Step 2: Update the Ruby support declarations**

Set `.ruby-version` to:

```text
4.0.5
```

Set the gemspec declaration to:

```ruby
s.required_ruby_version = ">= 3.3.0"
```

Set the CI matrix to:

```yaml
ruby-version: [head, 4.0, 3.4, 3.3]
```

- [ ] **Step 3: Validate dependency resolution under Ruby 4.0.5**

Run:

```bash
ruby --version \
  && bundle check
```

Expected: Ruby reports `ruby 4.0.5`; Bundler reports that all dependencies are satisfied. If `bundle check` reports missing dependencies, run `bundle install` and retain only lockfile changes required for Ruby 4.0.5.

- [ ] **Step 4: Run the project verification suite**

Run:

```bash
bundle exec rspec \
  && bundle exec srb typecheck \
  && bundle exec rubocop \
  && bundle exec rake build
```

Expected: all specs pass, Sorbet reports no errors, RuboCop reports no offenses, and RubyGems builds the gem. If a command fails because of Ruby 4.0.5, make the smallest source or dependency change that resolves that specific failure, then rerun the entire command sequence.

- [ ] **Step 5: Check declarations and the resulting diff**

Run:

```bash
test "$(< .ruby-version)" = "4.0.5" \
  && rg -n 'required_ruby_version = ">= 3\.3\.0"' geet.gemspec \
  && rg -n 'ruby-version: \[head, 4\.0, 3\.4, 3\.3\]' .github/workflows/ci.yml \
  && ! rg -n '3\.4\.6|required_ruby_version = ">= 3\.2\.0"|ruby-version: \[head, 4\.0, 3\.4, 3\.3, 3\.2\]' . --glob '!docs/superpowers/**' --glob '!.git/**' \
  && git diff --check \
  && git status --short
```

Expected: exit status 0, only intended files are modified, and the diff has no whitespace errors.

- [ ] **Step 6: Commit the upgrade**

```bash
git add .ruby-version geet.gemspec .github/workflows/ci.yml Gemfile.lock \
  && git commit -m "Upgrade development Ruby to 4.0.5"
```

Omit `Gemfile.lock` from `git add` if it did not change. Add any verified compatibility fix files to the same command.
