workflow "Terraform" {
  on = "pull_request"
  resolves = ["terraform-validate"]
}

action "terraform-validate" {
  uses = "innovationnorway/terraform-action/validate@master"
  secrets = ["GITHUB_TOKEN"]
}

workflow "Release" {
  on = "push"
  resolves = ["semantic-release"]
}

action "semantic-release" {
  uses = "innovationnorway/semantic-release-action@beta"
  secrets = ["GH_TOKEN"]
}
