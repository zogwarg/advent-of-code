#!/usr/bin/env jq -n -rR -f

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

def print:
  ([ .wall, .seen | keys[] | fromjson ] | [
    (min_by(.[0]), max_by(.[0]) | .[0]),
    (min_by(.[1]), max_by(.[1]) | .[1])
  ]) as [$xmin,$xmax,$ymin,$ymax] |

  .target as [[$tx,$ty]] |

  reduce(
    ( .wall | keys[] | fromjson + ["█"]),
    ( .seen | keys[] | fromjson + [" "])
  ) as [$x,$y,$t] (
    [range(1+$ymax-$ymin) | [range(1,$xmax-$xmin) | "▓"]];
    .[$y-$ymin][$x-$xmin] = $t
  )

  | .[-$ymin][-$xmin] = "S"
  | if $tx then .[$ty-$ymin][$tx-$xmin] = "o" end
  | ( .[0] | length ) as $w
  | ( .[] ), [limit($w;repeat("-"))] | add
;


def BFS($func; $t):
  {
    bots: [ { pos: [0,0], $func, d: 0 } ],
    seen: {
      "[0,0]": 0
    },
    wall: {},
    i: 0
  } | # Do BFS search, copying $func state as needed, cond stop
  until (isempty( .bots[] ) or .i >= 5000 or ( $t and .target );
    .bots[0] as $bot | .bots = .bots[1:] | .i += 1 | reduce(
      (
        $bot.pos
        | (. + [1] | .[1] -= 1 ), (. + [2] | .[1] += 1 ),    # N, S
          (. + [3] | .[0] -= 1 ), (. + [4] | .[0] += 1 )     # W, E
      ) as $d
      | select( (.seen["\($d[0:2])"] or .wall["\($d[0:2])"]) | not )
      | [ $d[2], $d[0:2], "\($d[0:2])" ]
    ) as [$i, $d, $k] (.;
      callFunc($bot.func;{out:[],in:[$i]}) as $func |
        if $func.out == [0] then
        .wall[$k] = true
      elif $func.out == [1] then
        .seen[$k] = $bot.d + 1 |
        .bots += [ {pos: $d, $func, d: ($bot.d + 1) } ]
      else
        .target = [$d, ($bot.d + 1), $bot.func]
      end
    )
  )
;

BFS(BFS($func;true).target[2];false)

# Pretty-print #
| debug(print) |

if .i >= 5000 then
   "Did not fill the maze" | halt_error
else
  [ .seen[] ] | max + 1
end
