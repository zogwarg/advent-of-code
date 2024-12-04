#!/usr/bin/env jq -n -R -f

[ inputs / "" ] | [.,.[0]|length] as [$H,$W] | [
  range($H) as $y | range($W) as $x | def z: select(.>=0);
  ( .[$y][$x:$x+4]       ),               # ─ Horizontal #
  [ .[$y:$y+4][] | .[$x] ],               # │ Vertical   #
  [ range(4) as $i | .[$y+$i][$x+$i  ] ], # ╲ Diagonal   #
  [ range(4) as $i | .[$y+$i][$x-$i|z] ]  # ╱ Diagonal   #
  | add | select(. == "XMAS" or . == "SAMX")
] | length
