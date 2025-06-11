#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

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
  # Risk level
  ) + 1
]

# Output total risk level
| add
