workflow "Jekyll build now" {
  resolves = ["AsciiDoc to Jekyll"]
  on = "push"
}

action "AsciiDoc toJekyll" {
  uses = "./"
  env = {
    SRC = "sample_site"
    DEST = "build"
  }
}
