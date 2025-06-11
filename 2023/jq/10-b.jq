#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

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
{heads:[ $s ], d:[]} |

until(.heads | length == 0;
  # Record "visits" in flat array of bools d = [ ...in_loop(i) ]
  .d[(.heads[])] = true | .d as $d |
  # Update search heads, without adding an already visited node.
  .heads |= [ extend_loop(.[]) | select($d[(.)]|not)]
) |

# Make array full
.d[$w*$h] = false |

# $loop = String with only the pipe
( .d[:-1] | to_entries | map(if .value then $grid[.key:.key+1] else " " end) | add ) as $loop |

# Get number of nodes inside the loop
reduce (
  range($h) as $y | range($w) as $x | [ [0,$y], [$x, $y] ] | map(to_idx(.))
) as [$z,$i] (0;
  # If an element is not on the loop itself
  if ($loop[$i:$i+1] == " " ) and (
      $loop[$z:$i]           # For each row, from left
    | gsub("F-*J|L-*7"; "|") # F---J and L---7 are equivalent to "|" for parity
    | gsub("F-*7|L-*J"; "" ) # F---7 and L---J are equivalent to " " for parity
    | gsub("[^|]";"")        # Only keeping "|"
    | length % 2 == 1        # Crossing odd "|" means inside, even means outside
  ) then . + 1 else . end
)
