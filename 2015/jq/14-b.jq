#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Reindeer speed, duration, & rest numbers
[ inputs | [ scan("\\d+") | tonumber ] ] |

map (
  [
    # Get reindeer covered distance for each second
    range(1;2503+1) as $i |
    # Distance covered by full "run + rest" periods
    ( $i / ( .[1] + .[2] ) | floor ) * .[1] * .[0] +
    # Distance covered: for remainder "extra" time
    ([ .[1], ( $i % ( .[1] + .[2] ) ) ] | min) * .[0]
  ]
)

# 1 point to the reindeer in the lead at each second
| transpose
| map(max as $m | map(if . == $m then 1 else 0 end))
| transpose

# Best score
| map(add)
| max
