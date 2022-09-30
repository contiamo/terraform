terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.1"
    }
  }
}
provider "github" {
  owner = "contiamo"
  # token = var.github_token
  # token = GITHUB_TOKEN
}

resource "github_repository" "project_repo" {
  name        = var.repo_name
  description = var.repo_description
  auto_init = true
  visibility = "private"
  allow_auto_merge = true
  vulnerability_alerts = true
  delete_branch_on_merge = true
  has_wiki = false
  has_issues = false
  has_projects = false
}

# This can be used to create branches:
# resource "github_branch" "main" {
#   repository = github_repository.project_repo.name
#   branch     = "main"
# }

# Github creates "main" branch by default. We therefore can simply reference it below:
resource "github_branch_default" "default"{
  repository = github_repository.project_repo.name
  branch     = "main"
}

resource "github_branch_protection_v3" "main_branch_protections" {
  repository = github_repository.project_repo.name
  branch = "main"
  require_conversation_resolution = true
  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}

# Add collaborators set in the value file to the repo:
resource "github_repository_collaborator" "repo_user_from_values" {
  for_each = var.repo_collaborators
  repository = github_repository.project_repo.name
  username   = each.key
  permission = each.value
}

# Give contiamo-ci user admin rights:
resource "github_repository_collaborator" "repo_user_ci" {
  repository = github_repository.project_repo.name
  username   = "contiamo-ci"
  permission = "admin"
}

output "repo_url" {
  value = github_repository.project_repo.html_url
}
