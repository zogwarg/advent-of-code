#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Get all ingredients with associated cap, dur, flav, text, & calo values
[ inputs | [ scan("-?\\d+") | tonumber ] ] | . as $ing | length as $num |

# Create all possible portion arrangements
def portions($tot; $num):
  if $num == 1 then [$tot] else
    range($tot+1) as $t | [ $t ] + portions($tot - $t; $num - 1)
  end
;

# Calculate
def arrangement_value:
  [ ., $ing] | transpose | map(.[0] as $m | .[1] | map(. * $m))
  | transpose | map(add | if . > 0 then . else 0 end) |
  .[0] * .[1] * .[2] * .[3]
;

[ # Return portion arrangement
  # With maximum value
  portions(100;$num) | arrangement_value
] | max
