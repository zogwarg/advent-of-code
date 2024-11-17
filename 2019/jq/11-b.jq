#!/usr/bin/env jq -n -rR -f

# Define function, and inputs
{
  s: (inputs / "," | map(tonumber)), # Stack state
  c: 0,                              # Current  postion counter
  b: 0,                              # Relative  base  position
  in:  [],                           # Input  array, left first
  out: []                            # Output array, left first
} as $func |

def group_of($n): . as $in | [ range(0;length;$n) | $in[.:(.+$n)] ];
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

{
  func: $func, # Initialize stack state
  pos: [0,0],  # Initial robot position
  dir: [0,1],  # Initial robot direction
  shp: {}      # Painted ship-coordinates
} |

until(.func.term;
  # Run program                      ┌─ Input from camera  ┌─ Default
  .func = callFunc(.func; {out:[] , in:[.brd["\(.pos)"] // 1]     }) |
  .brd["\(.pos)"] = .func.out[0]| # Paint current position with output
  .func = callFunc(.func; {out:[],in:[.func.out[0]]})| # Update camera

  .dir = ({                    # Turn Robot
     "[0,1,0]": [-1,0],  "[1,0,0]": [0, 1],
     "[0,1,1]": [ 1,0],  "[1,0,1]": [0,-1],
    "[0,-1,0]": [ 1,0], "[-1,0,0]": [0,-1],
    "[0,-1,1]": [-1,0], "[-1,0,1]": [0, 1],
  }["\(.dir + .func.out)"] // .dir )

  # Move forwards
  | .pos[0] += .dir[0] | .pos[1] += .dir[1]
) |


[ .brd | to_entries[] | select(.value == 1) | (.key | fromjson) ] |
[
  (min_by(.[0]),max_by(.[0])).[0],
  (min_by(.[1]),max_by(.[1])).[1]
] as [ $xmin,$xmax, $ymin,$ymax ]|

reduce .[] as [$x,$y] (
  [ range(1+$ymax-$ymin) | [ range(2+$xmax-$xmin) | " " ] ];
  .[$ymax-$y-1+$ymin][$x-$xmin] = "▇"
) |

[ .[] | join("") | debug ] as $d |

# Make display to letter map
(
  [
    # Font map - Some values are assumed
    # A      B        C        D        E
    " ▇▇  ", "▇▇▇  ", " ▇▇  ", "▇▇▇  ", "▇▇▇▇ ",
    "▇  ▇ ", "▇  ▇ ", "▇  ▇ ", "▇  ▇ ", "▇    ",
    "▇  ▇ ", "▇▇▇  ", "▇    ", "▇  ▇ ", "▇▇▇  ",
    "▇▇▇▇ ", "▇  ▇ ", "▇    ", "▇  ▇ ", "▇    ",
    "▇  ▇ ", "▇  ▇ ", "▇  ▇ ", "▇  ▇ ", "▇    ",
    "▇  ▇ ", "▇▇▇  ", " ▇▇  ", "▇▇▇  ", "▇▇▇▇ ",
    # F      G        H        I        J
    "▇▇▇▇ ", " ▇▇  ", "▇  ▇ ", " ▇▇▇ ", "  ▇▇ ",
    "▇    ", "▇  ▇ ", "▇  ▇ ", "  ▇  ", "   ▇ ",
    "▇▇▇  ", "▇    ", "▇▇▇▇ ", "  ▇  ", "   ▇ ",
    "▇    ", "▇ ▇▇ ", "▇  ▇ ", "  ▇  ", "   ▇ ",
    "▇    ", "▇  ▇ ", "▇  ▇ ", "  ▇  ", "▇  ▇ ",
    "▇    ", " ▇▇▇ ", "▇  ▇ ", " ▇▇▇ ", " ▇▇  ",
    # K       L        M       N
    "▇  ▇ ", "▇    ", " ▇ ▇ ", "▇   ▇", " ▇▇  ",
    "▇ ▇  ", "▇    ", "▇▇▇▇▇", "▇▇  ▇", "▇  ▇ ",
    "▇▇   ", "▇    ", "▇ ▇ ▇", "▇ ▇ ▇", "▇  ▇ ",
    "▇ ▇  ", "▇    ", "▇ ▇ ▇", "▇ ▇ ▇", "▇  ▇ ",
    "▇ ▇  ", "▇    ", "▇   ▇", "▇  ▇▇", "▇  ▇ ",
    "▇  ▇ ", "▇▇▇▇ ", "▇   ▇", "▇   ▇", " ▇▇  ",
    # P      Q        R        S        T
    "▇▇▇  ", " ▇▇  ", "▇▇▇  ", " ▇▇▇ ", "▇▇▇▇▇",
    "▇  ▇ ", "▇  ▇ ", "▇  ▇ ", "▇    ", "  ▇  ",
    "▇  ▇ ", "▇  ▇ ", "▇  ▇ ", "▇    ", "  ▇  ",
    "▇▇▇  ", "▇ ▇▇ ", "▇▇▇  ", " ▇▇  ", "  ▇  ",
    "▇    ", "▇  ▇ ", "▇ ▇  ", "   ▇ ", "  ▇  ",
    "▇    ", " ▇▇ ▇", "▇  ▇ ", "▇▇▇  ", "  ▇  ",
    # U      V        W        X        Y
    "▇  ▇ ", "▇   ▇", "▇   ▇", "▇   ▇", "▇   ▇",
    "▇  ▇ ", "▇   ▇", "▇   ▇", " ▇ ▇ ", "▇   ▇",
    "▇  ▇ ", "▇   ▇", "▇ ▇ ▇", "  ▇  ", " ▇ ▇ ",
    "▇  ▇ ", " ▇ ▇ ", "▇ ▇ ▇", " ▇ ▇ ", "  ▇  ",
    "▇  ▇ ", " ▇ ▇ ", "▇▇▇▇▇", "▇   ▇", "  ▇  ",
    " ▇▇  ", "  ▇  ", " ▇ ▇ ", "▇   ▇", "  ▇  "
  ] | [
    (
      # Reshape input into proper keys
      [ group_of(5) | transpose[] | group_of(6)[] | add ] |
      [ group_of(5) | transpose[][] ]
    ),
    ( "ABCDEFGHIJKLMNOPQRSTUVWXY" / "")
  ] | transpose | map({(.[0]):.[1]}) | add

  # Add missing Z
  | .[
    [
      "▇▇▇▇ ",
      "   ▇ ",
      "  ▇  ",
      " ▇   ",
      "▇    ",
      "▇▇▇▇ "
    ] | add
  ] = "Z"
) as $to_letter |

[ map(group_of(5))|transpose[]|[.[]|add]|$to_letter[add] // "_" ]| add
