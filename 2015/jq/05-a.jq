#!/usr/bin/env jq -n -R -f
[
  inputs | select(test(".*[aeiou].*[aeiou].*[aeiou]") and test ("(.)\\1") and (test("ab|cd|pq|xy")| not))
] | length
