#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Get low-high
inputs / "-" | map(tonumber) as [$low, $high] |
# Sum all valid "passwords"
[
  range($low; $high + 1) | tostring | select(
    test("^1*2*3*4*5*6*7*8*9*$") and ( . / "" | group_by(.) | map(length) | contains([2]))
  ) | 1
] | add
