#!/bin/sh
# \
exec jq -n -f "$0" "$@"

 # ┌──Outlet
 # ▼ Adapters
([ 0, inputs ] | sort) as $inputs |

# Init state for main reduce loop
def init: reduce (
  $inputs[1:4][] as $i | (1,2,3) as $d | select($i - $d >= 0) | [$i, $d]
) as [$i, $d] ([1];    # 0 as "one" way to be  arranged  starting from 0
  .[$i] += .[$i - $d]  # Number of ways at $i is sum of ways at $i-1,2,3
);

reduce (  # Sliding window of 4 check previous 3
  $inputs | range(4;length) as $i | .[$i-3:$i+1]
) as [$a,$b,$c,$x] ( init;
  # Sum previous states if reachable
  if $x - $a <= 3 then .[$x] += .[$a] else . end |
  if $x - $b <= 3 then .[$x] += .[$b] else . end |
  if $x - $c <= 3 then .[$x] += .[$c] else . end
)

# Output total number
# Of adapter combinations
| last
