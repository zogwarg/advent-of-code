#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

[
  inputs / "\t" | map(tonumber) | first(
    combinations(2) | select(.[1] != .[0]) | sort | .[1] / .[0] | select(. == floor)
  )
] | add
