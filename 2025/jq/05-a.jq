#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

inputs | trim / "\n\n" | [ .[] / "\n"     # Parse into:           #
  | [ .[] | [ scan("\\d+") | tonumber ] ] # [ [[range1], ... ],   #
] | [                                     #   [[n1],[n2],... ]  ] #
  .[1][][0] as $n #──── Test Every Ingredient ID                  #
  | select(any(.[0][]; .[0] <= $n and .[1] >= $n)) | $n           #
] | length # └───────── Keep If matches any fresh range           #
