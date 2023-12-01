#!/usr/bin/env jq -n -rR -f
[
  inputs / "\t" | map(tonumber) | first(
    combinations(2) | select(.[1] != .[0]) | sort | .[1] / .[0] | select(. == floor)
  )
] | add
