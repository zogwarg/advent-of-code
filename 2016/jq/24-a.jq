#!/usr/bin/env jq -n -R -f

[ inputs / "" ] as $grid |

(
  [ # Get all locations in airducts
    $grid
  | to_entries[] | .key as $j | .value
  | to_entries[] | .key as $i
  | select(.value != "#" and .value != ".")
  | [[$i,$j],.value]
  ] | sort_by(.[1])
) as $loc |

# Get distance between source and sink
def bfs($source;$sink):
  {
    search: [[$source, 0]],
    seen: {"\($source)": 0}
  } |
  until (isempty(.search[]) or .seen["\($sink)"];
    .search[0] as [$s, $d] | .search |= .[1:] |
    reduce (
      $s |
      (.[0] += 1), (.[0] -= 1),
      (.[1] += 1), (.[1] -= 1)
      | select($grid[.[1]][.[0]] != "#")
      | [ ., $d + 1]
    ) as $n (.;
      if (.seen["\($n[0])"]|not) then
        .search += [$n] |
        .seen["\($n[0])"] = $n[1]
      end
    )
  ) | .seen["\($sink)"]
;

(
  [ # Get shortest distance between every pair
    $loc
  | combinations(2) | select(.[0][1] < .[1][1])
  | [ ([.[][1]]) , bfs(.[0][0];.[1][0]) ]
  | {"\(.[0])":.[1]}, {"\(.[0]|reverse)":.[1]}
  ] | add
) as $dists |

# Since there are few locations
# Brute-forcing the permutations
def perms:
  if length == 1 then . else
  .[] as $c | ( . - [$c] | perms) as $arr | [$c, $arr[]]
  end
;

[ # Get path visiting all nodes, in minimum number of steps
  [ $loc[1:][][1] ] | ["0"] + perms |
  [ range(length-1) as $i | .[$i:$i+2] | $dists["\(.)"] ] | add
] | min
