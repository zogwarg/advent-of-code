#!/usr/bin/env jq -n -rR -f

reduce(
  inputs / " " | .[] |= if tonumber? // false then tonumber end
) as $op ("abcdefgh" / "";
  # Apply rules in succession to starting string "abcdefgh"
  if $op[0:2] == ["swap","position"] then
    .[$op[2]] as $X | .[$op[2]] =  .[$op[5]] | .[$op[5]] = $X
  elif $op[0:2] == ["swap", "letter"] then
    [ index($op[2], $op[5]) ] as [ $i, $j ] |
    .[$i] as $X | .[$i] = .[$j] | .[$j] = $X
  elif $op[0:2] == ["rotate", "left"] then
    .[$op[2]:] + .[:$op[2]]
  elif $op[0:2] == ["rotate", "right"] then
    .[length-$op[2]:] + .[:length-$op[2]]
  elif $op[0:2] == ["rotate", "based"] then
    index($op[-1]) as $i |
    ( if $i >= 4 then length - (2 + $i)
      else length - (1 + $i) end ) as $r |
    .[$r:] + .[:$r]
  elif $op[0:2] == ["reverse","positions"] then
    ([ $op[2], $op[4]]  | sort ) as [ $i, $j ] |
    .[:$i] + ( .[$i:$j+1] | reverse ) + .[$j+1:]
  elif $op[0:2] == ["move", "position"] then
    .[$op[2]] as $X |
    del(.[$op[2]]) | .[:$op[5]] + [$X] + .[$op[5]:]
  else
    "Unexpected op: \($op)" | halt_error
  end
  # Output final result
) | add
