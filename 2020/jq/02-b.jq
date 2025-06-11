#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce (
  inputs
  # Parse line
  | (split(":? |-"; "")
  | .[0:2] |= map(tonumber))
  | .[0:3] as [ $i, $j, $l ]
  # Get letters as positions $i and $j
  | .[3] |= ( .[$i-1:$i] + .[$j-1:$j] | gsub("[^\($l)]";"_"))
  # Is password valid ?
  | [ "_\($l)", "\($l)_" ] as $valid
  | if [ .[3] == $valid[] ] | any then 1 else 0 end
) as $line (0; . += $line)
