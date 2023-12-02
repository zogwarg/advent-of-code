#!/usr/bin/env jq -n -R -f
reduce (
  inputs
  # Parse line
  | (split(":? |-"; "")
  | .[0:2] |= map(tonumber))
  | .[0:3] as [ $min, $max, $l ]
  # Count occurences of policy letter
  | .[3] |= ( gsub("[^\($l)]";"") | length )
  # Is password valid ?
  | if .[3] >= $min and .[3] <= $max then 1 else 0 end
) as $line (0; . += $line)
