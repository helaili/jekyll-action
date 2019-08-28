workflow "Jekyll build now" {
  resolves = [
    "Jekyll Action",
  ]
  on = "push"
}

action "Jekyll Action" {
  uses = "simple_site"
  secrets = ["GITHUB_TOKEN"]
}
