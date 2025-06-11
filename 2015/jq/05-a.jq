#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  inputs | select(test(".*[aeiou].*[aeiou].*[aeiou]") and test ("(.)\\1") and (test("ab|cd|pq|xy")| not))
] | length
