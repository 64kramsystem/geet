# Geet

Command line interface for performing Git hosting service operations.

The current version supports creating a PR, but the whole project is a work in progress (currently, no help, and no testing suite).

## Samples

Create an issue, adding the label matching `bug`, and assigning it to the collaborators matching `john`, `tom`, `kevin`:

    $ geet issue 'Issue Title' 'Issue Description' --label-patterns "code review" --assignee-patterns john,tom,kevin

Create a PR, adding the label matching `code review`, and requesting reviews from the collaborators matching `john`, `tom`, `adrian`:

    $ geet pr 'PR Title' 'PR Description
    > 
    > Closes #1' --label-patterns "code review" --reviewer-patterns john,tom,adrian

For the help:

    $ geet --help
