workflow "Jekyll build now" {
  resolves = ["AsciiDoc to Jekyll"]
  on = "push"
}

action "AsciiDoc to Jekyll" {
  uses = "./"
  env = {
    SRC = "sample_site"
    DEST = "build"
  }
  secrets = ["GITHUB_TOKEN"]
}
