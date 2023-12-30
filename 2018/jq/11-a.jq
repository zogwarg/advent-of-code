#!/usr/bin/env jq -n -r -f

inputs as $add |

[ # Get 3x3 square with highest power
  range(1;299) as $y |
  range(1;299) as $x |
  def power($x;$y):
    ($x + 10) as $rack |
    ( $rack * $y + $add ) * $rack % 1000 / 100 | floor - 5
  ;
  [
    [$x, $y],
    (
      [
        range($y;$y+3) as $y |
        range($x;$x+3) as $x |
        power($x;$y)
      ] | add
    )
  ]
] | max_by(.[1])

# Output top left corner
| .[0] | join(",")