#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / "" ] |           #   Get surface scan from Eris    #
                            #                                 #
[                           #                                 #
  [".",".",".",".","."],    #   Set empty board constant.     #
  [".",".",".",".","."],    #                                 #
  [".",".",".",".","."],    # For initial state when checking #
  [".",".",".",".","."],    #    Neighbours up and down.      #
  [".",".",".",".","."]     #                                 #
] as $empty |

def step($g;$up;$down):     # Step including boards up & down #
  reduce ($g
    | to_entries[] | .key as $y  | .value
    | to_entries[] | .key as $x  | .value as $v
    | select($x != 2 or $y != 2) # Never update the center square
    | [
        # Normal neighbour updates.
        $g[$y-1|select(.>=0 and ($x != 2 or . != 2))][$x],
        $g[$y+1|select(.<=4 and ($x != 2 or . != 2))][$x],
        $g[$y][$x+1|select(.<=4 and ($y != 2 or . != 2))],
        $g[$y][$x-1|select(.>=0 and ($y != 2 or . != 2))],
        # On outer edge, check single neighbour up.
        ( if $y == 0 then $up[1][2] else empty end ),
        ( if $y == 4 then $up[3][2] else empty end ),
        ( if $x == 0 then $up[2][1] else empty end ),
        ( if $x == 4 then $up[2][3] else empty end ),
        # On inner edge, check whole row of neighbours down.
        ( if [$x,$y] == [2,1] then $down[0][] else empty end),
        ( if [$x,$y] == [2,3] then $down[4][] else empty end),
        ( if [$x,$y] == [1,2] then $down[][0] else empty end),
        ( if [$x,$y] == [3,2] then $down[][4] else empty end)
        | select(. == "#" )
      ]
    | if [$v,length] | . == [".", 1] or . == [".", 2] then [$x,$y,"#"]
    elif [$v,length] | .[0] == "#" and .[1] != 1      then [$x,$y,"."]
    else empty end   #   Only change squares that must be updated
  ) as [$x,$y,$c] ($g; .[$y][$x] = $c )
;

# Do 200 iterations
reduce range(200) as $i ({ up: [.], down: []};      debug({$i}) |
  ( .up, .down ) |= ( if .[-1] != $empty then . + [$empty] end) |
  # └─ If last items up or down not empty, populate next boards.

  reduce (    (.up|length) as $u | (.down|length) as $d |
    # First elements are always updated
    ["up"  , 0, step(  .up[0];.up[1];.down[0]          )],
    ["down", 0, step(.down[0];.up[0];.down[1] // $empty)],
    (
      range(1;$u) as $i |
      [
        "up", $i,
        step(  .up[$i];  .up[$i+1]//$empty;  .up[$i-1])
      ] # Update going up, using empty if required.
    ),
    (
      range(1;$d) as $i |
      [
        "down", $i,
        step(.down[$i];.down[$i-1];.down[$i+1]//$empty)
      ] # Update going down, using empty if required.
    )
  ) as [$k, $i, $b] (.; .[$k][$i] = $b)
)

# Count total number of bugs recursively
| [..|strings|select(. == "#")] | length
