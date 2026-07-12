# Ruby 4.0.5 Upgrade Design

## Scope

Use Ruby 4.0.5 as the project development version, raise the gem's minimum supported Ruby version from 3.2 to 3.3, and retain CI coverage for every supported Ruby minor version through 4.0 plus Ruby head.

## Changes

- Set `.ruby-version` to `4.0.5`.
- Set `required_ruby_version` to `>= 3.3.0` in `geet.gemspec`.
- Remove Ruby 3.2 from the CI matrix while retaining Ruby head, 4.0, 3.4, and 3.3.
- Re-resolve dependencies only if Ruby 4.0.5 requires lockfile changes.
- Make code or dependency changes only for incompatibilities demonstrated by verification.

## Verification

Under Ruby 4.0.5, install the locked bundle and run the RSpec suite, Sorbet typecheck, RuboCop, and gem build. Confirm the lockfile and repository contain no remaining declarations that incorrectly make Ruby 3.2 a supported version or Ruby 3.4.6 the development version.
