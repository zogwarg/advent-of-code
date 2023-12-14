#!/usr/bin/env jq -n -R -f

# Get heigthmap to grid
[ inputs / "" | map(tonumber) ] as $grid |

[ # Get dimensions
  ( $grid[0] |length ),
  ( $grid    |length )
] as [$w,$h] |

[ # Pad grid "10" box wall
  [range($w+2)|10],
  ($grid[] | [ 10, .[],  10 ]),
  [range($w+2)|10]
] as $padded |

[
  # Select all points that are lower than all their neighbours
  range(1;$w+1) as $x | range(1;$h+1) as $y | $padded[$y][$x] |
  select(. as $p |
    all(
      $padded[$y][$x+1],
      $padded[$y][$x-1],
      $padded[$y+1][$x],
      $padded[$y-1][$x];
      $p < .
    )
  # Coordinates
  ) | [$x, $y]
]

# Expand basins from low point list    # Until search heads are empty
| map({pool:[.], heads:[.]}) | until ( [ .[].heads[] ] | length == 0;
  # For each basin
  .[] |= (
    .pool as $p |

    ([ # Get list of points next to heads, that are higher and not in pool
      .heads[] as [$hx, $hy] |
      ([$hx+1,$hy],[$hx-1,$hy],[$hx,$hy+1],[$hx,$hy-1]) as [$x,$y] |
      select($padded[$y][$x] < 9 and $padded[$y][$x] > $padded[$hy][$hx]) |
      [$x,$y]
    ]| unique - $p ) as $new |

    # Expand pool & update heads
    .pool += $new | .heads = $new
  )
)

# Output product of the sizes of the three largest basins
| [ .[].pool | length ] | sort[-3:] |  .[0] * .[1] * .[2]
