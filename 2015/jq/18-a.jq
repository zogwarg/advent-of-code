#!/usr/bin/env jq -n -R -f

# Get elf game-of-life board: with off->0 and on->1
[ inputs / "" | map({".":0,"#":1}[.])] as $inputs |
($inputs   |length) as $H | # Height
($inputs[0]|length) as $W | # Width

# Play 100 cycles of the game of life.
reduce range(100) as $_ ($inputs;
  . = [
    range(0;$H) as $j | [
      range(0;$W) as $i | (
        if .[$j][$i] == 0 then
          if [
            range($j-1;$j+2) as $jj |
            range($i-1;$i+2) as $ii |
            select(
              ( $ii != $i or $jj != $j ) and$ii >= 0 and $ii  < $W and $jj >= 0 and $jj < $H
            ) | .[$jj][$ii]
          ] | add == 3
          then 1 else 0 end # Off light goes on if it has exactly three on neighbours
        else
          if [
            range($j-1;$j+2) as $jj |
            range($i-1;$i+2) as $ii |
            select(
              ( $ii != $i or $jj != $j ) and $ii >= 0 and $ii  < $W and $jj >= 0 and $jj < $H
            ) | .[$jj][$ii]
          ] | [ add ] | inside([2,3])
          then 1 else 0 end # On light goes off if it has too few or too many neighbours
        end
      )
    ]
  ]
)

# Total "on" lights
| [  .[][]  ] | add
