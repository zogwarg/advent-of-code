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
[ [$func, null ] | recurse(
  if .[0].term then empty end |
  callFunc(.[0];{in: [], out: []}) | [., .out[0]]
) | .[1] | numbers ] |

#--- Convert to string and pretty print. ---#
(implode|rtrimstr("\n\n")/"\n")| debug(.[]) |
#------–––––––––––––––––––––––––––––––––––––#
map(split(""))| [.,.[0]|length] as [$H, $W] |
reduce (# Find alignment of all intersections
  range(1;$H-1) as $y | range(1;$W-1) as $x |
  [ .[$y-1:$y+2][][$x-1:$x+2] ] == [
    [".","#","."],
    ["#","#","#"],
    [".","#","."]
  ] | select(.) | $x * $y
) as $i (0;.+$i)
