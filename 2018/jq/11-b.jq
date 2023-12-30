#!/usr/bin/env jq -n -r -f

inputs as $add |

[ # Fill power grid
  def power($x;$y):
    ($x + 10) as $rack |
    ( $rack * $y + $add ) * $rack % 1000 / 100 | floor - 5
  ;
    range(1;301) as $y |
  [ range(1;301) as $x | power($x;$y) ]
] as $grid |

[ # For each cell
  range(0;300) as $y |
  range(0;300) as $x |
  debug({$x,$y}) |
  [ # Find max square size with max power
    [$x+1,$y+1],
    reduce range(0;300 - ([$x,$y]|max)) as $i (
      [0,0,0]; # [Square size, Max Size, Prev Size power]
      .[2] += ([ $grid[$y+range(0;$i+1)][$x+$i]]|add) | # Right  edge
      .[2] += ([ $grid[$y+$i][$x+range(0;$i)]]  |add) | # Bottom edge
      if .[2] > .[1] then
        .[1] = .[2] | .[0] = $i + 1
      end
    )
  ]
]

# Output coordinates and size of
# The largest power square
| max_by(.[1][1])
| .[0] + [.[1][0]] | join(",")