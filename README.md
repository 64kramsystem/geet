[![Build Status][BS IMG]](https://travis-ci.org/saveriomiroddi/geet)

# Geet

Command line interface for performing Git hosting service operations.

The current version supports only creating PRs/issues.

This tool is very similar to [Hub](https://github.com/github/hub), but it supports a different set of operations, fully specified via command line.

Please see the [development status](#development-status) section for informations about the current development.

## Providers support

The functionalities currently supported are:

- Github:
  - create gist
  - create issue
  - create PR
  - list issues
  - list labels
  - list milestones
  - list PRs
  - merge PR
- Gitlab:
  - list issues
  - list labels

## Samples

### Prerequisite(s)

Geet requires the API token environment variable to be set, eg:

    export GITHUB_API_TOKEN=0123456789abcdef0123456789abcdef    # for GitHub
    export GITLAB_API_TOKEN=0123456789abcd-ef0-1                # for GitLab

All the commands need to be run from the git repository.

### Create an issue (with label and assignees)

Basic creation of an issue (after creation, will open the page in the browser):

    $ geet issue create 'Issue title' 'Multi
    > line
    > description'

More advanced issue creation, with labels and assignees:

    $ geet issue create 'Issue title' 'Issue description' --label-patterns bug,wip --assignee-patterns john

patterns are partial matches, so, for example, `johncarmack` will be matched as assignee in the first case.

### Create a PR (with label, reviewers, and assigned to self)

Basic creation of a PR (after creation, will open the page in the browser):

    $ geet pr create 'PR title' 'Description'

More advanced PR creation, with label and reviewers, assigned to self:

    $ geet pr create 'PR title' 'Closes #1' --label-patterns "code review" --reviewer-patterns kevin,tom,adrian

### List issues/PRs

List the open issues, in default order (inverse creation date):

    $ geet issue list
    > 16. Implement issue opening (https://github.com/saveriomiroddi/geet/issues/16)
    > 14. Update README (https://github.com/saveriomiroddi/geet/issues/14)
    > 8. Implement milestones listing/show (https://github.com/saveriomiroddi/geet/issues/8)
    > 4. Allow writing description in an editor (https://github.com/saveriomiroddi/geet/issues/4)
    > 2. Support opening PR into other repositories (https://github.com/saveriomiroddi/geet/issues/2)

List the open PRs, in default order (inverse creation date):

    $ geet pr list
    > 21. Add PRs listing support (https://github.com/saveriomiroddi/geet/pull/21)

### Create a gist

Create a private gist:

    $ geet gist create /path/to/myfile

Create a public gist, with description:

    $ geet gist create --public /path/to/myfile 'Gist description'

### Help

Display the help:

    $ geet [command [subcommand]] --help

Examples:

    $ geet --help
    $ geet pr --help
    $ geet pr create --help

## Development status

Geet is in alpha status. Although I use it daily, new features are frequently added, and internal/external APIs/workflows may change.

The public release will be 1.0, and is expected to be released in February 2018 or earlier.

[BS img]: https://travis-ci.org/saveriomiroddi/geet.svg?branch=master
