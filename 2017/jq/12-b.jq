#!/usr/bin/env jq -n -R -f

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

# Get group of programs from source
def bfs($s):
  {
    search: [$s],
    seen: {$s:true}
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
  ) | .seen | keys
;

{
  programs: keys,
  groups: 0
} |
until(isempty(.programs[]);
  .programs -= bfs(.programs[0]) |
  .groups += 1
  # Output total number of groups
) | .groups
