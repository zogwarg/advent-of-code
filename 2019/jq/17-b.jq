#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

# Define function, and inputs
{
  s: (inputs / "," | map(tonumber)), # Stack state
  c: 0,                              # Current  postion counter
  b: 0,                              # Relative  base  position
  in:  [],                           # Input  array, left first
  out: []                            # Output array, left first
} as $func |

def to_str($seq): $seq|map(tostring)|join(",")+",";

def toInt($bool): if $bool then 1 else 0 end;
def callFunc($func; $io):
  $func + $io | until(
    # Exit if opcode is not of type 1-9, or if output queue not empty.
    ([.s[.c] % 100] | inside([range(1;10)])|not) or (.out|length > 0);

    # Get opcode and parameter modes
    ( .s[.c] | [ . % 100 ]) as [$op] |
    ( .s[.c] | [ . / 100 |
      (. % 10              ),
      (. % 100 / 10 | floor),
      (. / 100      | floor)
    ]) as [ $ma, $mb, $mc ] |

    # Overly greedy parameter match
    .s[.c+1:.c+4] as [$a, $b, $c] |

    [
        if $ma == 1 then       $a
      elif $op == 3
       and $ma != 2 then       $a
      elif $op == 3 then    .b+$a
      elif $ma == 2 then .s[.b+$a] // 0
                    else .s[   $a] // 0 end,
        if $mb == 1 then       $b
      elif $mb == 2 then .s[.b+$b] // 0
                    else .s[   $b] // 0 end,
        if $mc == 2 then    .b+$c
                    else       $c       end
    ] as [$am,$bm,$cm] | # Apply param modes

      if $op == 1 then .c += 4 | .s[$cm] = $am + $bm # ADD
    elif $op == 2 then .c += 4 | .s[$cm] = $am * $bm # MULTIPLY
    elif $op == 3 then .c += 2 | .s[$am] = .in[0] | .in=.in[1:] # READ
    elif $op == 4 then .c += 2 | .out = .out + [$am] # WRITE
    elif $op == 5 then .c=(if $am==0 then .c+3 else $bm end) # JUMP-IF
    elif $op == 6 then .c=(if $am!=0 then .c+3 else $bm end) # JUMP-NE
    elif $op == 7 then .c += 4 | .s[$cm] = toInt($am <  $bm) # TEST-LT
    elif $op == 8 then .c += 4 | .s[$cm] = toInt($am == $bm) # TEST-EQ
                  else .c += 2 | .b = .b + $am end # RELATIVE-BASE UPD

  )
  # Provide termination state.
  | if .s[.c] % 100 == 99 then .term = true else . end
;

# Recurse function until output is complete
last([ ($func | .s[0] = 2), [] ] | recurse(
    .[1] as $out |# Recursive function call
    if .[1][-2:] == [10,10]then empty end |
    callFunc( .[0] ; { in: [], out: [] }) |
    [., ( $out + .out) ]
  )                        # Saving last: #
) | .[0] as $func | .[1] | #    $func     #

#--- Convert to string and pretty print. ---#
(implode|rtrimstr("\n\n")/"\n")| debug(.[]) |
#------–––––––––––––––––––––––––––––––––––––#
map(split(""))| [.,.[0]|length] as [$H, $W] |

[                                     #     #
               [ range($W+2) | "." ], #  P  #
  (.[] as $l | [  ".",  $l[] , "." ]),#  A  #
               [ range($W+2) | "." ]  #  D  #
] |                                   #     #

[
  ([range(9) | "."]|.[4] = "#")| #  .  #
  (.[1,5] = "#"),(.[3,1] = "#"), # └ ┘ #
  (.[3,7] = "#"),(.[7,5] = "#"), # ┐ ┌ #
  ((3,1,7,5) as $i|.[$i] = "#")  | add
] as [ $L, $J, $a7, $F, $l, $u, $d, $r ] |

[ # Find coordinates for all the joints
  range(1;$H+1) as $y | range(1;$W+1) as $x |
  [ .[$y-1:$y+2][][$x-1:$x+2] ] | (map(add)|add) |
    if . == $F then [$x,$y,"F"] elif . ==$a7 then [$x,$y,"7"]
  elif . == $L then [$x,$y,"L"] elif . == $J then [$x,$y,"J"]
  elif gsub("[><^v]";"#") == $u then  [ $x, $y, "u", .[4:5] ]
  elif gsub("[><^v]";"#") == $d then  [ $x, $y, "d", .[4:5] ]
  elif gsub("[><^v]";"#") == $l then  [ $x, $y, "l", .[4:5] ]
  elif gsub("[><^v]";"#") == $r then  [ $x, $y, "r", .[4:5] ]
  else empty end
]

| {
    joints: (. - [ max_by(.[3]) ] | map(.[0:3]) ),
    c: (max_by(.[3]))       # Current position  #
  }
| .dir = {                  #                   #
    "^":[0,-1],"V":[0,1],   # Current direction #
    "<":[-1,0],">":[1,0]    #                   #
  }[.c[3]]
| .axs = {                  #                   #
    "^":0,"V":0,"<":1,">":1 # Axis of direction #
  }[.c[3]]                  #       ---         #
| .icd = [1,0][.axs]        #   Inc Dimension   #
| .turn = {
    "l^": "L", "r^": "R",   #                   #
    "u<": "R", "d<": "L",   #                   #
    "lv": "R", "rv": "L",   # Apply first turn. #
    "u>": "L", "u<": "R"    #                   #
  }["\(.c[2:]|add)"]        #                   #

| until (isempty(.joints[]) or .i > 5000; .i += 1 | .seq += [ .turn ]
  | .c as $c    |                                 # Update seq L or R
  .dir = {
    "0-1L":[-1,0],"-10L":[0, 1], "01L":[ 1,0], "10L":[0,-1],
    "0-1R":[ 1,0],"-10R":[0,-1], "01R":[-1,0], "10R":[0, 1]
  }["\([.dir[], .turn | tostring]|add)"] | .dir as $dir
  | .axs = .icd | .icd = [1,0][.axs] ######################
  | .axs as $j  | .icd as $i       | ######## Complete Turn


  ([ # Find the next joint, first on the same axis/dir
    .joints[] | select(.[$j] == $c[$j])
              | . + [ $c[$i] - .[$i] | . * - $dir[$i] ]
              | select(.[3] > 0)
  ]| min_by(.[3]) | .[0:3]) as $next | .c = $next     |

  #  Update remaining joints  #     Update seq with distance     #
  .joints = .joints - [$next] | .seq += [$next[$i] - $c[$i]|abs] |

  .turn = { ####### Prepare next Turn ##########
    "0-17":"L","-10F":"L", "01L":"L", "10J":"L",
    "0-1F":"R","-10L":"R", "01J":"R", "107":"R"
  }["\([ .dir[], $next[2] | tostring ] | add )"]

) | debug({seq}) | .seq | . as $seq | to_str($seq) as $S |


[ # Test valid subdivisions of main program
  range(2;10;2) as $lA | to_str($seq[0:$lA])       as $A |
  range(2;10;2) as $lB | to_str($seq[$lA:$lA+$lB]) as $B |
  ( $S | capture(
    "^\($A)\($B)(\($A)|\($B))*(?<C>.+?)(\($A)|\($B))").C
  ) as $C |
  select($S | test("^\($A)\($B)(\($A)|\($B)|\($C))+$") ) |
  [$A,$B,$C | .[0:-1]]
] as [[$A,$B,$C]] |

([
  $S |
  (indices($A)|map([.,"A"])), #     Get order       #
  (indices($B)|map([.,"B"])), #        of           #
  (indices($C)|map([.,"C"]))  #    subroutines      #
  | .[]
] | sort_by(.[0]) | map(.[1]) | join(",")) as $MAIN |

debug({$MAIN,$A,$B,$C}) |

[
  $MAIN,$A,$B,$C,"n"| . + "\n" | explode[]
] as $in |

# Loop function over MAIN,A,B,C,"n" input
[ [($func | .in = $in), null ] | recurse(
  if .[0].term then empty end |
  callFunc(.[0];{out: []}) | [., .out[0]]
) | .[1] | numbers ]

| debug( .[:-1] | implode / "\n" | .[] )

| .[-1] # Output all robo-collected dust.
