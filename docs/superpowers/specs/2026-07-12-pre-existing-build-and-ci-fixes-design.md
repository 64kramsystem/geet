# Pre-existing Build and CI Fixes Design

## Scope

Fix the two pre-existing project issues exposed during Ruby 4.0.5 verification: the CI test job supplies the wrong token variable, and Rake does not define Bundler's standard gem tasks.

## Changes

- Rename the CI environment key from `GITHUB_API_TOKEN` to `GH_TOKEN`, matching the application, README, and test harness contract.
- Require `bundler/gem_tasks` from `Rakefile` so `rake build` and the standard Bundler gem tasks are available.
- Do not add token aliases, fallback credentials, dependency updates, or unrelated build changes.

## Verification

Run the specs using the same `GH_TOKEN` environment contract as CI, then run Sorbet, RuboCop, the default Rake task, and `rake build`. Remove the generated gem artifact and confirm the diff contains only the CI workflow and Rakefile changes.
