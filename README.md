# Geet

Command line interface for performing Git hosting service operations.

The current version supports only creating PRs/issues.

This tool is very similar to [Hub](https://github.com/github/hub), but it supports more complex operations, fully specified via command line.

## Samples

Basic creation of an issue and a PR (both actions will open the pages with the result in the browser):

    $ geet issue create 'Issue Title' 'Issue Description'
    
    $ geet pr create 'PR Title' 'Multi-line
    > 
    > description'

More advanced issue/PR creation, with label, reviewers and assignees:

    $ geet issue create 'Issue Title' 'Issue Description' --label-patterns bug,wip --assignee-patterns john
    
    $ geet pr create 'PR Title' 'Closes #1' --label-patterns "code review" --reviewer-patterns kevin,tom,adrian

patterns are partial matches, so, for example, `johncarmack` will be matched as assignee in the first case.

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

For the help:

    $ geet --help
