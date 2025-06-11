#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Parse inputs to grid
[
  inputs / ""
] as $grid |
( $grid[0] | length ) as $W |
( $grid    | length ) as $H |

# Add start and end positions as "slopes"
( $grid | ( .[0][1], .[-1][-2] ) |= "v") as $grid |

[ # Get all slopes, as the nodes of the DAG
  $grid
  | to_entries[] | .key as $j | .value
  | to_entries[] | .key as $i | [[$i,$j],.value]
  | select(.[1] | . == ">" or . == "v"  or . == "^" or . == "<")
] as $nodes |

# Function to find connected nodes, in the DAG
def find_next_nodes($node):
  {
    "v": { step: [ 0, 1], next: [[-1, 1,"<"], [ 1, 1,">"], [ 0, 2,"v"]]},
    ">": { step: [ 1, 0], next: [[ 1,-1,"^"], [ 1, 1,"v"], [ 2, 0,">"]]},
    "^": { step: [ 0,-1], next: [[-1,-1,"<"], [ 1,-1,">"], [ 0,-2,"^"]]},
    "<": { step: [-1, 0], next: [[-1,-1,"^"], [-1, 1,"v"], [-2, 0,"<"]]}
  } as $dirs |

  # If next step is node, produce it and stop recursion on that branch
  $node as [[$x,$y],$dir,$dist] | $dirs[$dir] as {$step,$next} |
  if $grid[$y+$step[1]][$x+$step[0]] == $dir then
    [ [($x+$step[0]),($y+$step[1])], $dir, $dist+1]
  else
    # Otherwise create new heads for each possible direction to take on
    # Next square, and recursively search
    $next[] as [$dx,$dy,$ndir] |
    if $grid[$y+$dy][$x+$dx] | . == "." or . == $ndir then
      find_next_nodes([[($x+$step[0]),($y+$step[1])], $ndir, $dist+1])
    else
      empty
    end
  end
;

(
  [ # Get DAG
    $nodes[]
    | [ .[0], find_next_nodes([.[0],.[1],0])]
    | ( .[0], .[1:][][0] ) |= "\(.)"
    | {(.[0]): .[1:]}
  ] | add
) as $dag |

{
  search: [{ pos: "[1,0]", depth: 0 }],
  seen: { "[1,0]": 0 }
} |

# No negative loops, and DAG
# BFS will work fine
until (isempty(.search[]);
  .search[0] as $curr | .search |= .[1:] |
  reduce (
    $dag[$curr.pos][]
    | {pos: .[0], depth: ($curr.depth + .[2])}
  ) as $new (.;
    if ( .seen[$new.pos] // 0 ) < $new.depth then
      .search += [$new] |
      .seen[$new.pos] = $new.depth
    end
  )
)

# Output longest hike, reaching the end point
| .seen["\([($W-2),($H-1)])"]
