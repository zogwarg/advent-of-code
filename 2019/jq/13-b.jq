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


{ func: ($func|.|.s[0]=2) , out: [] } | until (
  .func.term or (.out[-1][0]) == -1;
  .func = callFunc(.func; {out: []}) | .func.out as $a |
  .func = callFunc(.func; {out: []}) | .func.out as $b |
  .func = callFunc(.func; {out: []}) | .func.out as $c |
  .out += [[$a[], $b[], $c[]] | select(length==3)]
) |

# Count total number of breakable blocks
([ .out[] | select(.[-1] == 2)] | length) as $blocks |

debug(
  [ # Debug output, board state
    reduce .out[0:-1][] as [$x,$y,$t] ([];
      .[$y][$x] = (" ▇#_o"[$t:$t+1])
    ) | ( .[] | add | debug )
  ] | "---------------------------------------------"
) |

def get_score:
  def get_x:
    .ball_x = ( last(.out[] | select(.[-1] == 4) | .[0]) // .ball_x )|
     .pad_x = ( last(.out[] | select(.[-1] == 3) | .[0]) //  .pad_x );

  get_x | .out = [] | # Update position of ball and pad
  until (
    .func.term or (.out[-1][0]) == -1;
    (
        if .ball_x == .pad_x then 0      #                         #
      elif .ball_x >  .pad_x then 1      #       Follow Ball       #
                             else -1 end #                         #
    ) as $i |
    .func = callFunc(.func; {in: [$i], out: []}) | .func.out as $a |
    .func = callFunc(.func; {          out: []}) | .func.out as $b |
    .func = callFunc(.func; {          out: []}) | .func.out as $c |
    .out += [  [ $a[], $b[], $c[] ] | select(length==3) ]          |
    get_x # Update position of ball and pad
  )
;

# Break all blocks
reduce range($blocks) as $_ (.; debug($_) | get_score)

# Output final score
| .out[-1][-1]
