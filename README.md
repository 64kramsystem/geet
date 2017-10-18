# Geet

Command line interface for performing Git hosting service operations.

The current version supports only creating PRs/issues.

This tool is very similar to [Hub](https://github.com/github/hub), but it supports more complex operations, fully specified via command line.

## Samples

Basic creation of an issue and a PR (both actions will open the pages with the result in the browser):

    $ geet issue create 'Issue Title' 'Issue Description'
    
    $ geet pr create 'PR Title' 'PR Description
    > 
    > Closes #1' --label-patterns "code review" --reviewer-patterns john,tom,adrian

Create an issue, adding the label matching `bug`, and assigning it to the collaborators matching `john`, `tom`, `kevin`:

    $ geet issue create 'Issue Title' 'Issue Description' --label-patterns "code review" --assignee-patterns john,tom,kevin

Create a PR, adding the label matching `code review`, and requesting reviews from the collaborators matching `john`, `tom`, `adrian`:

    $ geet pr create 'PR Title' 'PR Description
    > 
    > Closes #1' --label-patterns "code review" --reviewer-patterns john,tom,adrian

List the open issues, in default order (inverse creation date):

    $ geet issue list
    > 16. Implement issue opening (https://github.com/saveriomiroddi/geet/issues/16)
    > 14. Update README (https://github.com/saveriomiroddi/geet/issues/14)
    > 8. Implement milestones listing/show (https://github.com/saveriomiroddi/geet/issues/8)
    > 4. Allow writing description in an editor (https://github.com/saveriomiroddi/geet/issues/4)
    > 2. Support opening PR into other repositories (https://github.com/saveriomiroddi/geet/issues/2)

For the help:

    $ geet --help
