workflow "Jekyll build now" {
  resolves = [
    "Jekyll Action",
  ]
  on = "push"
}

action "Jekyll Action" {
  uses = "./"
  needs = "Filters for GitHub Actions"
  secrets = ["GITHUB_TOKEN"]
}

action "Filters for GitHub Actions" {
  uses = "actions/bin/filter@master"
  args = "branch master"
}
