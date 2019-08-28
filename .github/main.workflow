workflow "Jekyll build now" {
  resolves = [
    "Jekyll Action",
  ]
  on = "push"
}

action "Jekyll Action" {
  uses = "sample_site"
  secrets = ["GITHUB_TOKEN"]
}
