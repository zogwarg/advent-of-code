#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  inputs
  # Split winning numbers | card
  | split(" | ")
  # Get numbers, remove game id
  | .[] |= [ match("\\d+"; "g").string | tonumber ] | .[0] |= .[1:]
  # Get score for each line
  | .[1] - (.[1] - .[0]) | length | select(. > 0) | pow(2; . - 1)
]

# Output total score sum
| add
