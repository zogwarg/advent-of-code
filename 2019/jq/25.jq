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
def wantInput: (.s[.c] % 100 == 3 and (.in|length) == 0);
def callFunc($func; $io):
  $func + $io | until(
    # Exit if opcode is not of type 1-9, or if output queue not empty.
    ([.s[.c] % 100] | inside([range(1;10)])|not) or (.out|length > 0)
    or wantInput; # Blocking on input

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

# Get current state, after sending a command, (room, doors, items, ?)
def readScreen: .out // .func.out | implode | [
    [scan("== .+ ==")[3:-3]],
    [(scan("Doors here lead:.+?\n\n";"m")[16:-2]/"\n- "|.[1:])],
    [(scan("Items here:.+\n\n";"m")[11:-2]/"\n- "|.[1:])],
    [(scan("Command\\?"))]
  ]
;

# Pretty print output
def printScreen: .out // .func.out | implode / "\n" | .[];

# Make a move, and wait for input prompt
def play($func;$input):
  {$func, out: [] } | .func.in = ($input|explode + [10]) |
  until(.func.term or (.func|wantInput); # Stop on prompt.
    .func = callFunc(.func;{out:[]}) | .out += .func.out
  ) | .func.out = .out # Output as function with
    | .func            # Full output
;

( # Initial state for BFS accross all rooms and items.
       play($func;"") as $start                     |
  ($start|readScreen) as [[$room],[$dirs],[$items]] |
  {
    search: [{func:$start,$room,$dirs,$items,prev:[]}],
    prev: {
      "\([$room,[]])": [] # Node = (room x item set)
    }                     # Inefficient but works
  }
) |

until (isempty(.search[]); .search[0] as $u | .search = .search[1:] |
  reduce (
       $u.dirs[] as $d                         #
    | play($u.func; $d)                        # Visit next rooms,
    |          . as $func                      # and update function
    | readScreen as [[$room],[$dirs],[$items]] # state
    | {$func,$room,$dirs,$items,$d}            #
  ) as {$func,$room,$dirs,$items,$d} (.;

    (
      ($items // []) - [
           "photons", "molten lava",    # Ignore Items that are:
        "infinite loop", "escape pod",  # - Dangerous
             "giant electromagnet"      # - Crash or Exit game
      ]
    ) as $items |

    (
      if ($items|length) > 0 then
        ($items| map("take \(.)")) | [ play($func; .|join("\n")), . ]
      else
        [ $func , [] ]     # Immediately pick up items in next room
      end
    ) as [ $func, $take ] | ( $u.items + $items | unique) as $items |


    if .prev["\([$room,$items])"]|not then
       # Keep shortest path to current state
       .prev["\([$room,$items])"] = $u.prev + [$d] + $take |
       .search += [
         { $func,$room,$dirs,$items,prev: ($u.prev+[$d]+ $take) }
       ]
    end | debug([$room,$items])
  )
)

| "Pressure-Sensitive Floor" as $target | .prev
# Get path to pressure sensitive floor, with all items
| to_entries | map(.key|= fromjson) | map(select(.key[0] == $target))
| max_by(.key[1] | length) | . as {key: [$_, $items], value: $steps }

# Visit one room before, with all items
| play($func; $steps[0:-1]|join("\n")) as $func

# First drop all items, then test if any is too heavy.
| .func = play($func; $items|map("drop \(.)")|join("\n"))
| [
    $items[] as $item
    | play(.func; "take \($item)\n" + $steps[-1] )
    | [ printScreen | scan("lighter") ]
    | select(length > 0)
    | $item | debug("\(.) is too heavy on it's own!")
  ] as $heavy       #  ┌─ Reversing is faster for my input
| ( $items - $heavy | reverse | map("drop \(.)")) as $drops

# Drop heavy items
| .func = play($func; $heavy|map("drop \(.)")+["inv"]|join("\n")) |

first(
  ( # Guessing three extra drops are needed
    [$drops,$drops,$drops]
    | combinations | unique | debug(.) | join("\n")
  ) as $drop |
  .func = play(.func; $drop+"\nsouth\n" ) |
  select([printScreen|scan("lighter|heavier")|debug(.)]|length == 0)|
  # Get code from first run to not trigger warning
  printScreen | debug | scan("\\d{4,}") | tonumber
)