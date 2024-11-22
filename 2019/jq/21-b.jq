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

{ $func, out: []} |
.func.in = ([
  # Can only jump when D is SOLID, MUST NOT jump if CANT jumping again
  # ->( D & !(!E & !H )) & (!A | !B | !C) ) + Should only jump if hole
  # Re-ordering:
  # -> D & ( !(!E & !H) & (!A | !B | !C) )
  # -> D & ( (E|H) & (!A|!B|!C) )
  # -> D & ( (E&!A) | (E&!B) | (E&!C) | (H&!A) | (H&!B) | (H&!C))
  #                   ######─────────────┐
  "NOT A J", #            ║  ABCDEFGH  ║ └─ Ignore ##.__##___ subcase
  "AND E J", # (E && !A)  ║ #.__##___  ║
  "NOT C T", #    ||      ║            ║
  "AND E T", # (E && !C)  ║ ##_.##___  ║
   "OR T J", #    ||      ║            ║
  "NOT A T", #    ||      ║            ║
  "AND H T", # (H && !A)  ║ #.__#.__#  ║
   "OR T J", #    ||      ║            ║
  "NOT B T", #    ||      ║            ║
  "AND H T", # (H && !B)  ║ ##._#.__#  ║
   "OR T J", #    ||      ║            ║
  "NOT C T", #    ||      ║            ║
  "AND H T", # (H && !C)  ║ ###.#.__#  ║
   "OR T J", #            ║            ║
  "AND D J", #   AND D    ╚════════════╝
      "RUN"]
| join("\n") + "\n"
| explode ) |
until(.func.term;
  .func = callFunc(.func;{out:[]}) | .out = .out + .func.out
)

| .out | debug(.[:-1] | implode / "\n" | .[])[-1]