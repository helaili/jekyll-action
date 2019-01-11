workflow "New workflow" {
  on = "label"
  resolves = ["AsciiDoc to Jekyll"]
}

action "AsciiDoc to Jekyll" {
  uses = "./"
  env = {
    SRC = "sample_site"
    DEST = "build"
  }
}
