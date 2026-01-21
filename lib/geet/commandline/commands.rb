# frozen_string_literal: true
# typed: strict

module Geet
  module Commandline
    module Commands
      GIST_CREATE_COMMAND = T.let("gist.create", String)
      ISSUE_CREATE_COMMAND = T.let("issue.create", String)
      LABEL_CREATE_COMMAND = T.let("label.create", String)
      ISSUE_LIST_COMMAND = T.let("issue.list", String)
      LABEL_LIST_COMMAND = T.let("label.list", String)
      MILESTONE_CLOSE_COMMAND = T.let("milestone.close", String)
      MILESTONE_CREATE_COMMAND = T.let("milestone.create", String)
      MILESTONE_LIST_COMMAND = T.let("milestone.list", String)
      PR_COMMENT_COMMAND = T.let("pr.comment", String)
      PR_CREATE_COMMAND = T.let("pr.create", String)
      PR_LIST_COMMAND = T.let("pr.list", String)
      PR_MERGE_COMMAND = T.let("pr.merge", String)
      PR_OPEN_COMMAND = T.let("pr.open", String)
      REPO_ADD_UPSTREAM_COMMAND = T.let("repo.add_upstream", String)
      REPO_OPEN_COMMAND = T.let("repo.open", String)
    end
  end
end
