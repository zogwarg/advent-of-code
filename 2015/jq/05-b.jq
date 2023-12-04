#!/usr/bin/env jq -n -R -f
[
  inputs | select(test("(.).\\1") and test ("(..).*\\1"))
] | length
