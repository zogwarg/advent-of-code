#!/bin/sh
# \
exec jq -n -f "$0" "$@"

{
  l: [ inputs ],
  p: 0,
  s: 0
} | .len = (.l | length) | until (.p >= .len;
  # Faster to use vars, and straight assigments
  # This task is sadly slow in jq (only matters for part b)
  .p as $p | .l[$p] as $lp | .s = (.s + 1) |
  .p = $p + $lp | .l[$p] = (if $lp > 2 then $lp - 1 else $lp + 1 end)
)

# Output number of steps
| .s
