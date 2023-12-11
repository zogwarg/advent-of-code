#!/usr/bin/env jq -n -R -f

# Get inputs    | Set expansion ratio
[ inputs / "" ] |  1000000 as $exp |

# Get "condensed" expanded grid.
[

  [ # Replace "." with 1s
    .[] | map(if . == "." then 1 else . end) |

    # Expand rows that are all "."
    if [.[] == 1] | all then map($exp) else . end
  ]
  # Transpose
  | transpose
  # Expand columns that contain no galaxies
  | [ .[] | if [.[] | . == 1 or . == $exp] | all then map($exp * . ) else . end ]
  # Transpose back
  | transpose[]
] |

# Get single string grid, and W x H dimensions, and num_grid for distance()
( .[0] | length ) as $w |
( length ) as $h |
[ .[][] | if . ==  "#" then . else "." end ] as $str_grid |
[ .[][] | if . ==  "#" then 1 else  .  end ] as $num_grid |

# Get distance between two points
# (by flat index)
def distance($i1;$i2):
  def get_xy($i): ($i % $w) as $x | ($i - $x | . / $w) as $y | [$x, $y] ;
  def to_idx($xy): $xy[1] * $w + $xy[0];

  (get_xy($i1)) as [$ax, $ay] |
  (get_xy($i2)) as [$bx, $by] |

  # Accumlate distance going "down", then "right" (no zig-zag)
  reduce (
    $num_grid[to_idx(range($ax;$bx;copysign(1;$bx-$ax))|[.,$ay])],
    $num_grid[to_idx(range($ay;$by;copysign(1;$by-$ay))|[$bx,.])]
  ) as $i (0; . + $i)
;

[
  # For all pairs of galaxies
  $str_grid | indices("#") | combinations(2) | select(.[0] < .[1]) |
  # Compute distance
  distance(.[0];.[1])
  # Output total pairwise distance
] | add
