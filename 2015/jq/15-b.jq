#!/usr/bin/env jq -n -R -f

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
  | transpose | map(add | if . > 0 then . else 0 end)
  # Only keep recipes with calories == 500
  | select(.[4] == 500)
  | .[0] * .[1] * .[2] * .[3]
;

[ # Return portion arrangement
  # With maximum value and calorie = 500
  portions(100;$num) | arrangement_value
] | max
