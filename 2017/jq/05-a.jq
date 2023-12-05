#!/usr/bin/env jq -n -f
{
  l: [ inputs ],
  p: 0,
  s: 0
} | .len = (.l | length) | until (.p >= .len;
  # Faster to use vars, and straight assigments
  # This task is sadly slow in jq (only matters for part b)
  .p as $p | .l[$p] as $lp | .s = (.s + 1) |
  .p = $p + $lp | .l[$p] = ($lp + 1)
)

# Output number of steps
| .s
