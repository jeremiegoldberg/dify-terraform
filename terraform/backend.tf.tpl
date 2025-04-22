terraform {
  backend "http" {
    address        = "https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/terraform/state/default"
    lock_address   = "https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/terraform/state/default/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/terraform/state/default/lock"
    username       = "${GITLAB_USERNAME}"
    password       = "${GITLAB_TOKEN}"
    lock_method    = "POST"
    unlock_method  = "DELETE"
  }
}