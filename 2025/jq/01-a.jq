#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce (
  inputs | [ scan("[LR]"), (scan("\\d+") | tonumber) ]
) as [$D, $V] (
  { # Directions  # Clicks #    Mirror Helper    #
    L: 50, R: 50, z: 0,    rev: { L: "R", R: "L" }
  };
    .[$D]       = ( .[$D] +   $V  ) % 100 #  main  dial #
  | .[.rev[$D]] = (  100  - .[$D] ) % 100 # mirror dial #
  | if .[$D] == 0 then .z += 1 end        #   clicks    #
) | .z
