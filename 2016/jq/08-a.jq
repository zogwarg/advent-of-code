#!/usr/bin/env jq -n -R -f

# Screen Dimensions
[50, 6] as [$w, $h] |

reduce (
  inputs | [
    scan("(rect|col|row)")[],
  ( scan("\\d+") | tonumber )
  ]
) as $op ([range($w * $h) | false];
  if $op[0] == "rect" then
    .[ range($op[1]) as $x | range($op[2]) as $y | $x + $y * $w ] = true
  elif $op[0] == "row" then
    $op[1:] as [ $y , $s ] |
    .[$y*$w:$y*$w+$w] = .[$y*$w+$w-$s:$y*$w+$w] + .[$y*$w:$y*$w+$w-$s]
  else
    $op[1:] as [ $x , $s ] |
    reduce (. as $d | range($h) as $y | [$y , $d[$x + $y * $w ]]) as [$y,$v] (.;
      .[$x + ( ( $y + $s ) % $h) * $w] = $v
    )
  end
)

# Output number of lit items
| [ .[] | select(.) ] | length
