workflow "Terraform" {
  on = "push"
  resolves = ["terraform-fmt"]
}

action "terraform-fmt" {
  uses = "innovationnorway/terraform-action@master"
  args = ["fmt", "-check", "-list", "-recursive"]
}

workflow "Release" {
  on = "push"
  resolves = ["semantic-release"]
}

action "semantic-release" {
  uses = "innovationnorway/semantic-release-action@beta"
  secrets = ["GH_TOKEN"]
}
