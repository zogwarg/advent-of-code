#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

[
  # Split groups  | Count all unique letter in each group      | Flatten
  inputs / "\n\n" | map(gsub("\n";"") / "" | unique | length ) | .[]
] | add
