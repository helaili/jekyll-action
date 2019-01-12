workflow "Jekyll build now" {
  resolves = ["Jekyll Action"]
  on = "push"
}

action "Jekyll Action" {
  uses = "./"
  env = {
    SRC = "sample_site"
    DEST = "build"
  }
  secrets = ["GITHUB_TOKEN"]
}
