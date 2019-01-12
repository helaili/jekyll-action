workflow "Jekyll build now" {
  resolves = ["Jekyll Action"]
  on = "push"
}

action "Jekyll Action" {
  uses = "./"
  env = {
    SRC = "sample_site"
  }
  secrets = ["GITHUB_TOKEN"]
}
