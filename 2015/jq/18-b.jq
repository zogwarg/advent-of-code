#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Get elf game-of-life board: with off->0 and on->1
[ inputs / "" | map({".":0,"#":1}[.])] as $inputs |
($inputs   |length) as $H | # Height
($inputs[0]|length) as $W | # Width

# Play 100 cycles of the game of life.
reduce range(100) as $_ (
  $inputs | (.[0][0], .[0][-1], .[-1][0], .[-1][-1]) = 1;
  . = [
    range(0;$H) as $j | [
      range(0;$W) as $i | (
        ([
          range($j-1;$j+2) as $jj   |   range($i-1;$i+2) as $ii   |
          select($ii >= 0 and $ii < $W and $jj >= 0 and $jj < $H) |
          .[$jj][$ii]
        ] | add ) as $r |
        if $r == 3 or (.[$j][$i] == 1 and $r == 4) then 1 else 0 end
      )
    ]
  ] | (.[0][0], .[0][-1], .[-1][0], .[-1][-1]) = 1 # Keep corner lights on
)

# Total "on" lights
| [  .[][]  ] | add
