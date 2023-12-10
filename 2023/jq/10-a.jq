#!/usr/bin/env jq -n -R -f

# Parse inputs to grid
[ inputs ] | [(add|.,index("S")),(.[0] | length),length] as [$grid,$s,$w,$h] |

# Functions: idx <-> [x,y]
def get_xy($i): ($i % $w) as $x | ($i - $x | . / $w) as $y | [$x, $y] ;
def to_idx($xy): $xy[1] * $w + $xy[0];

# Make valid loop extensions
def extend_loop($i): get_xy($i) as [$x, $y] | $grid[$i:$i+1] as $c |
  (
    # Left
    to_idx([$x-1, $y] | select(.[0] >= 0)) | select(
      ($grid[.:.+1] | inside("F-L") ) and ($c | inside("J-7S"))
    )
  ),
  (
    # Right
    to_idx([$x+1, $y] | select(.[0] < $w)) | select(
      ($grid[.:.+1] | inside("J-7") ) and ($c | inside("F-LS"))
    )
  ),
  (
    # Up
    to_idx([$x, $y-1] | select(.[1] >= 0))  | select(
      ($grid[.:.+1] | inside("F|7") ) and ($c | inside("L|JS"))
    )
  ),
  (
    # Down
    to_idx([$x, $y+1] | select(.[1] < $h)) | select(
      ($grid[.:.+1] | inside("L|J") ) and ($c | inside("F|7S"))
    )
  )
;

# Start exploration at "S", distance 0
{heads:[ $s ],ld: 0,d:[]} |

until(.heads | length == 0;
  # Record "visits" in flat array of dists d = [ ...dist(i) ]
  .d[.heads[]] = .ld | .d as $d | .ld += 1 |
  # Update search heads, without adding an already visited node.
  .heads |= [ extend_loop(.[]) | select($d[.]|not)]
)

# Output max distance from "S"
| .d | max
