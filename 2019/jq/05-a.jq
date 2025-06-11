#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Define function, and inputs
{
  s: (inputs / "," | map(tonumber)),
  c: 0,
  in: [1],
  out: []
} as $func |

$func | until(
  # Exit if opcode is not of type 1,2,3,4
  [.s[.c] % 100] | inside([1,2,3,4]) | not;

  # Get opcode and mode
  ( .s[.c] | [ . % 100 , . / 100 | floor  ]) as [$op, $mode] |

  # Get parameters, and use position mode if applicable (never for $c)
  .s[.c+1:.c+4] as [$a, $b, $c] |
  (if $mode % 10 == 1 then $a else .s[$a] end) as $am |
  (if ( $mode // 0 ) / 10 | floor == 1 then $b else .s[$b] end) as $bm |

  # Add
  if $op == 1 then
    .s[$c] = $am + $bm |
    .c += 4
  # Multiply
  elif $op == 2 then
    .s[$c] = $am * $bm |
    .c += 4
  # Store Input | always $a not $am
  elif $op == 3 then
    .s[$a] = .in[0] | .in |= .[1:] |
    .c += 2
  # Add output
  else
    .out += [$am] |
    .c += 2
  end
)

# Output diagnostic code
| .out[-1]
