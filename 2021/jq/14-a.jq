#!/usr/bin/env jq -n -sR -f

inputs | rtrimstr("\n") / "\n\n"

| ( .[1] / "\n" | map([scan("\\w+")] | {(.[0]): .[1]} ) | add) as $R |

# Simple iterative approach #
reduce range(10) as $i (.[0];
  reduce (
    range(length) as $i | .[$i:$i+2] | .[0:1] + ( $R[.] // "" )
  ) as $s (""; . + $s)
)

| . / "" | group_by(.) | map({(.[0]):length})
| add    | debug       | map(.)  | max - min
