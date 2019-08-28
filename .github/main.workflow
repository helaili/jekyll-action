workflow "Jekyll build now" {
  resolves = [
    "Jekyll Action",
  ]
  on = "push"
}

action "Jekyll Action" {
  uses = "./"
  secrets = ["GITHUB_TOKEN"]
  env = {
    SRC = "sample_site"
  }
}
