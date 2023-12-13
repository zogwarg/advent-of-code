#!/usr/bin/env jq -n -R -f

# Define function, and inputs
{
  s: (inputs / "," | map(tonumber)), # Stack state
  c: 0,                              # Current  postion counter
  b: 0,                              # Relative  base  position
  in: [],                            # Input  array, left first
  out: []                            # Output array, left first
} as $func |

# Call func wrapper, allowing iteration:
# $func param alows preserving stack state
def callFunc($func; $io):
  $func + $io | until(
    # Exit if opcode is not of type 1-9
    ([.s[.c] % 100] | inside([1,2,3,4,5,6,7,8,9]) | not)
    # Pause excution after output,
    or (.out | length > 0);

    # Get opcode and mode
    ( .s[.c] | [ . % 100 ]) as [$op] |
    ( .s[.c] | [ . / 100 |
      (. % 10 ),
      (. % 100 / 10|floor),
      (. / 100 | floor)
    ]) as $mode |

    # Greedily get parameters, and applying mode
    .s[.c+1:.c+4] as [$a, $b, $c] |
    (
      if  $mode[0]  == 1 then $a
      # "Store op" is always an address
      elif $op      == 3 then .b+$a
      elif $mode[0] == 2 then .s[.b+$a]
      else .s[$a] end
    ) as $am |
    (
      if   $mode[1] == 1 then $b
      elif $mode[1] == 2 then .s[.b+$b]
      else .s[$b] end
    ) as $bm |
    (
      if $mode[2] == 2 then .b+$c
      else $c end
    ) as $cm |

    # Add
    if $op == 1 then
      .s[$cm] = $am + $bm |
      .c += 4
    # Multiply
    elif $op == 2 then
      .s[$cm] = $am * $bm |
      .c += 4
    # Store Input | always $a not $am
    elif $op == 3 then
      .s[$am] = .in[0] | .in |= .[1:] |
      .c += 2
    # Add output
    elif $op == 4 then
      .out += [$am] |
      .c += 2
    # Jump if $am is "true"
    elif $op == 5 then
      if $am == 0 then
        .c += 3
      else
        .c = $bm
      end
    # Jump if $am is "false"
    elif $op == 6 then
      if $am == 0 then
        .c = $bm
      else
        .c += 3
      end
    # Store "true" if $am < $bm
    elif $op == 7 then
      .s[$cm] = (if $am < $bm then 1 else 0 end) |
      .c += 4
    # Store "true" if $am == $bm
    elif $op == 8 then
      .s[$cm] = (if $am == $bm then 1 else 0 end) |
      .c += 4
    # Change relative base
    else
      .b += $am |
      .c += 2
    end
  )
  # Provide termination state.
  | if .s[.c] % 100 == 99 then .term = true else . end
;

# Call function
{func: callFunc($func;{in:[1]}), out: [] } | until(.func.term;
  .out += (.func.out) |
  .func = callFunc(.func;{out:[]})
)

# Output result, with no failed op codes
| .out + .func.out | .[0]
