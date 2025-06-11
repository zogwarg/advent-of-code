#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

# Define function, and inputs
{
  s: (inputs / "," | map(tonumber)), # Stack state
  c: 0,                              # Current  postion counter
  b: 0,                              # Relative  base  position
  in:  [],                           # Input  array, left first
  out: [],                           # Output array, left first
  i: null,                           # Execution window
} as $func |

def toInt($bool): if $bool then 1 else 0 end;
def callFunc($func; $io):
  $func + $io | until(
    # Exit if opcode is not of type 1-9, or if output queue not empty.
    ([.s[.c] % 100] | inside([range(1;10)])|not) or (.out|length > 0)
    or (.i and .i > 100); if .i then .i=.i+1 end | # Execution window

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
    elif $op == 3 then .c += 2 | .s[$am] = (.in[0]//-1) | .in=.in[1:]
    elif $op == 4 then .c += 2 | .out = .out + [$am] # WRITE # └─READ
    elif $op == 5 then .c=(if $am==0 then .c+3 else $bm end) # JUMP-IF
    elif $op == 6 then .c=(if $am!=0 then .c+3 else $bm end) # JUMP-NE
    elif $op == 7 then .c += 4 | .s[$cm] = toInt($am <  $bm) # TEST-LT
    elif $op == 8 then .c += 4 | .s[$cm] = toInt($am == $bm) # TEST-EQ
                  else .c += 2 | .b = .b + $am end # RELATIVE-BASE UPD
  )
  # Provide termination state.
  | if .s[.c] % 100 == 99 then .term = true else . end
;

def callWindow($func): # Executes a function for set N iterations
  { func: callFunc($func; {out: [], i: 0}), out: [] }
  |                                       .out = .out + .func.out
  | until ( .func.i > 100 or .func.term ;
      .func = callFunc(.func; {out:[]}) | .out = .out + .func.out
    )
  | .func + {out}
;

{ name: "My wonderful network", nat: {last: null, y: null } }
| .pcs = [ range(50) as $id | callFunc($func; {in: [$id], i: 0}) ]
| .bus = (.pcs | map(.out)) | # Intialize bus from initial output.

until (.i > 5000 or .nat.done; .i += 1 | debug({i}) |

  if all(.bus[]|length; . == 0) then
    if .nat.cnt > 5 then
      debug({nat}) |
      .nat.cnt = 0 |
      if .nat.y == .nat.last[1] then
        .nat.done = true
      else
        .nat.y = .nat.last[1] |
        .pcs[0].in = .pcs[0].in + .nat.last
      end
    else
      .nat.cnt += 1 # Must be idle for at least 600 iterations
    end             # For network as whole to count as idle
  end |

  reduce (
    .bus                                     #       Read bus:
    | to_entries[]  | .key as $src           # .Save source address
    | .value as $in | range(0;$in|length;3)  # .Packet boundaries
    | $in[.:(.+3)]  | select(length == 3)    # .Keep complete packets
    | [$src, .]
  ) as [$src,[$id, $x, $y]] (.;        .bus[$src] = .bus[$src][3:] |
    if $id != 255 then                       #    └── Pop from bus
      .pcs[$id].in += [$x,$y]                #─────── Write to input
    else                                     #
      .nat.last = [$x,$y]                    #─────── Write to NAT
    end
    | .nat.cnt = 0                           # Reset idle counter
  ) |

  reduce range(50) as $id (.;
    .pcs[$id] = callWindow(.pcs[$id]) |      # N iterations for each
    .bus[$id] = .bus[$id] + .pcs[$id].out    # Write output to bus
  )
)

| .nat.y # First repeated Y value set to PC[0]
