#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  inputs | select(test("(.).\\1") and test ("(..).*\\1"))
] | length
