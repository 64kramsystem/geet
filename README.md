# Geet

Command line interface for performing Git hosting service operations.

The current version supports only creating PRs/issues.

This tool is very similar to [Hub](https://github.com/github/hub), but it supports more complex operations, fully specified via command line.

## Samples

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

    $ geet [command [subcommand]]--help

Examples:

    $ geet --help
    $ geet pr --help
    $ geet pr create --help
