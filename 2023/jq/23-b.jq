#!/usr/bin/env jq -n -R -f

[ # Parse inputs to grid, remove slopes.
  inputs / "" | map(if . != "#" then "." end)
] as $grid |

( $grid[0] | length ) as $W |
( $grid    | length ) as $H |

[ # Get intersections
  range(1;$H-1) as $y |
  range(1;$W-1) as $x |
  [
    range($y-1;$y+2) as $yy |
    range($x-1;$x+2) as $xx |
    $grid[$yy][$xx]
  ] |
  select(
    [.[1,3,4,5,7]] == [".",".",".",".","."] or # ┼
    [.[1,3,4,5]]   == [".",".",".","."]     or # ┴
    [.[1,3,4,7]]   == [".",".",".","."]     or # ┤
    [.[1,5,4,7]]   == [".",".",".","."]     or # ├
    [.[3,5,4,7]]   == [".",".",".","."]        # ┬
  ) | [$x,$y]
] as $intersections |

# Include start and end as "intersection" nodes
( [[1,0]] + $intersections + [[$W-2,$H-1]] ) as $nodes |
( $nodes | map({"\(.)":true}) | add ) as $is_node |

# Find adjacent nodes with distances for a given node
def find_adjacent($node):
  {
    search: [{pos: $node, depth:0}],
    seen: {"\(node)": 0}
  } |
  until (isempty(.search[]);
    .search[0] as $s | .search |= .[1:] |
    reduce (
      $s.pos
      | (.[0] -= 1), (.[0] += 1), (.[1] -= 1), (.[1] += 1)
      | select(.[0] >= 0 and .[1] >= 0)
      | select($grid[.[1]][.[0]] == ".")
      | {pos: ., depth: ($s.depth + 1) }
    ) as $new (.;
      if .seen["\($new.pos)"] then
        .
      elif $is_node["\($new.pos)"] then
        .adj += [[$new.pos, $new.depth]]
      else
        .search += [$new] |
        .seen["\($new.pos)"] = $new.depth
      end
    )
  ) | .adj[] | .[0] |= "\(.)"
;

( # Build graph of adjacent nodes
  [
    $nodes[] | {"\(.)": [find_adjacent(.)]}
  ] | add
) as $adj |

reduce(
  # Too lazy for dynamic programming
  # Bruteforcing the answer
  # Building all paths, that don't visit the same node twice
  [ "[1,0]", 0, {"[1,0]": true} ] | recurse(
    . as [$pos,$depth,$seen] |
    $adj[$pos][]
    | select($seen["\(.[0])"]| not) | .[1] += $depth | . as [$np, $nd] |
    [
      $np, $nd, ($seen | .["\($np)"] = true)
    ]
    # Keep the possible distances to the end
  ) | select(.[0] == "\([$W-2,$H-1])") | .[1]
) as $dist (0;
  # Output Maximum distance
  if $dist > . then
    $dist | debug
  end
)
