#!/usr/bin/env jq -n -sR -f
[
  # Split groups  | Count all unique letter in each group      | Flatten
  inputs / "\n\n" | map(gsub("\n";"") / "" | unique | length ) | .[]
] | add
