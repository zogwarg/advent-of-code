#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Reindeer speed, duration, & rest numbers
[ inputs | [ scan("\\d+") | tonumber ] ] |

map (
  # Distance covered by full "run + rest" periods
  ( 2503 / ( .[1] + .[2] ) | floor ) * .[1] * .[0] +
  # Distance covered: for remainder "extra" time
  ([ .[1], ( 2503 % ( .[1] + .[2] ) ) ] | min) * .[0]
) | max
