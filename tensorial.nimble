# Package

version       = "0.1.0"
author        = "Michael"
description   = "Algorithms for a simple tensor concept."
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 0.18.1"

proc testConfig =
  --define: release
  --define: openmp
  --forceBuild
  --passL: "-march=native"
  --passC: "-O3"
  --threads: on
  --run

task test, "run nimna tests":
  testConfig()
  setCommand "c", "tests/tall.nim"
