# Geet

Command line interface for performing Git hosting service operations.

The current version supports creating a PR, but the whole project is a work in progress (currently, no help, and no testing suite).

## Samples

Create a PR, assigning the labels matching `code review`, and requesting reviews from the collaborators matching `john`, `tom`, `adrian`:

    geet pr 'PR Title' 'PR Description' --label-patterns "code review" --reviewer-patterns john,tom,adrian

For the help:

    geet pr --help
