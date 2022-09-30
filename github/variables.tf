variable repo_name {
    type = string
    description = "Name of the repository to create."
}
variable repo_description {
    type = string
    description = "Description of the repository to create."
}

variable repo_collaborators {
  type = map(string)
  description = "List of Github usernames that should be added to the new Github repository as collaborators."
}
# variable "github_token" {
#   type = string
#   description = "Github personal access token"
# }
