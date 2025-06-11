#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  # Split on brackets[]
  inputs | split("\\[|\\]";"") |
  # Test even groups, outside brackets
  (
    [
      (range(length/2) | 2 * .) as $i | .[$i] / ""
      | [.[0:-2] , .[1:-1], .[2:]]
      | transpose[]
      | select(.[0] != .[1] and .[0] == .[2]) | .[0:2]
      | join("")
    ] | unique
  ) as $out |
  # Test odd groups, inside brackets
  (
    [
      (range(length/2) | 2 * . + 1) as $i | .[$i] // "" | . / ""
      | [.[0:-2] , .[1:-1], .[2:]]
      | transpose[]
      | select(.[0] != .[1] and .[0] == .[2]) | .[1:]
      | join("")
    ] | unique
  ) as $in |
  # Does "IP" suport SSL
  $in - ($in - $out) | length > 0 | select(.)
  # Count valid "IP"s
] | length
