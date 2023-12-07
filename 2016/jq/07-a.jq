#!/usr/bin/env jq -n -R -f
[
  # Split on brackets[]
  inputs | split("\\[|\\]";"") |
  # Test even groups, outside brackets
  (
    [
      (range(length/2) | 2 * .) as $i | .[$i] | test("(.)(?!\\1)(.)\\2\\1")
    ] | any
  # Test odd groups, inside brackets
  ) and (
    [
      (range(length/2) | 2 * . + 1) as $i | .[$i] // "" | test("(.)(?!\\1)(.)\\2\\1") | not
    ] | all
  ) | select(.)
  # Count total valid "IP"s
] | length
