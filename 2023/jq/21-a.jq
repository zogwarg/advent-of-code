#!/usr/bin/env jq -n -R -f

{ # Parse inputs to grid
  grid: [ inputs | sub("S"; "O") ]
} |

# Get grid dimensions
( .grid    | length ) as $H |
( .grid[0] | length ) as $W |

reduce range(64) as $_ (.grid | add / "";
  def get_xy($i):
    ($i % $W) as $x | ($i - $x | . / $W) as $y | [$x, $y]
  ;
  def to_idx($xy):
    $xy[1] * $W + $xy[0]
  ;

  def next_idx($current):
    [
      $current[] | get_xy(.) |
         ( .[0] -= 1),
         ( .[0] += 1),
         ( .[1] -= 1),
         ( .[1] += 1)
      | select(.[0] >= 0 and .[0] < $W and .[1] >= 0 and .[1] < $H)
      | to_idx(.)
    ] | unique[]
  ;
  debug($_)|

  # At eacg step update possible positions
  reduce next_idx(indices("O")) as $i (
    (.[] | select(. == "O")) |= ".";
    .[$i:$i+1] |= if . == ["#"] then ["#"] else ["O"] end
  )
)

# Output number of reachable garden plots
| [ .[] | select(. == "O") ] | length
