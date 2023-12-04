#!/usr/bin/env jq -n -R -f
[
  inputs | [ match("\\d+"; "g").string | tonumber ] |
  select(
    (.[0] >= .[2] and .[0] <= .[3] ) or ( .[1] >= .[2] and .[1] <= .[3]) or
    (.[2] >= .[0] and .[2] <= .[1] ) or ( .[3] >= .[0] and .[3] <= .[1])
  ) | 1
] | add
