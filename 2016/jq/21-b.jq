#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

# Only "difficult" operation to inverse
#
# ID | "Rotate based" of "12345678"
#---------------------------------------
# 0  | 81234567 | 1 -> inverse -> left 1
# 1  | 78123456 | 3 -> inverse -> left 2
# 2  | 67812345 | 5 -> inverse -> left 3
# 3  | 56781234 | 7 -> inverse -> left 4
# 4  | 34567812 | 2 -> inverse -> left 6
# 5  | 23456781 | 4 -> inverse -> left 7
# 6  | 12345678 | 6 -> inverse -> left 0
# 7  | 81234567 | 0 -> inverse -> left 1
#---------------------------------------
# Output positions are unique for input
# positions. Can be inversed according
# to table

reduce(
  [
    inputs / " " | .[] |= if tonumber? // false then tonumber end
  ] | reverse[] # Taking rules in reverse order
) as $op ("fbgdceah" / "";
  # Reverse the rules to unscramble "fbgdceah"
  if $op[0:2] == ["swap","position"] then
    # Swap pos is its own inverse
    .[$op[2]] as $X | .[$op[2]] =  .[$op[5]] | .[$op[5]] = $X
  elif $op[0:2] == ["swap", "letter"] then
    # Swap letter is its own inverse
    [ index($op[2], $op[5]) ] as [ $i, $j ] |
    .[$i] as $X | .[$i] = .[$j] | .[$j] = $X
  elif $op[0:2] == ["rotate", "left"] then
    # Inverse = Rotating Right
    .[length-$op[2]:] + .[:length-$op[2]]
  elif $op[0:2] == ["rotate", "right"] then
    # Inverse = Rotating Left
    .[$op[2]:] + .[:$op[2]]
  elif $op[0:2] == ["rotate", "based"] then
    # Inverse according to table
    index($op[-1]) as $i |
    [1,1,6,2,7,3,0,4][$i] as $r |
    .[$r:] + .[:$r]
  elif $op[0:2] == ["reverse","positions"] then
    # Reverse pos is its own inverse
    ([ $op[2], $op[4]]  | sort ) as [ $i, $j ] |
    .[:$i] + ( .[$i:$j+1] | reverse ) + .[$j+1:]
  elif $op[0:2] == ["move", "position"] then
    # Swapping X and Y as parameters is the inverse
    .[$op[5]] as $X |
    del(.[$op[5]]) | .[:$op[2]] + [$X] + .[$op[2]:]
  else
    "Unexpected op: \($op)" | halt_error
  end
  # Output final result
) | add
