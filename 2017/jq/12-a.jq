#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Get adjacency graph
reduce (
  inputs | [scan("\\d+")]
) as $pipe ({};
  $pipe[0] as $from |
  reduce $pipe[1:][] as $to (.;
    .[$from][$to] = 1 |
    .[$to][$from] = 1
  )
) | . as $graph |

{ # BFS from "0"
  search: ["0"],
  seen: {"0":true}
} |
until (isempty(.search[]);
  .search[0] as $s | .search |= .[1:] |
  reduce (
    $graph[$s] | keys[]
  ) as $n (.;
    if .seen[$n] | not then
      .search += [$n] |
      .seen[$n] = true
    end
  )
)

# Output total number of members
# Connected to "0"
| .seen | length
