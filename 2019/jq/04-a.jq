#!/usr/bin/env jq -n -R -f

# Get low-high
inputs / "-" | map(tonumber) as [$low, $high] |
# Sum all valid "passwords"
[ range($low; $high + 1) | tostring | select(test("^1*2*3*4*5*6*7*8*9*$") and test("(.)\\1")) | 1 ] | add
