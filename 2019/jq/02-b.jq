#!/usr/bin/env jq -n -R -f

# Define function
{
  s: (inputs / "," | map(tonumber)),
  c: 0,
} as $func |

# SELECT FIRST
first(

  # Call function $func($noun, $verb)
  $func | ( .s[1:3] , .args ) = ([range(100)] | combinations(2))

  | until (
    # Exit if opcode not 1 or 2
    [.s[.c]] | inside([1,2]) | not;

    # Parse current operation
    ([ .s[.c], .s[.s[.c + (1,2)]], .s[.c+3] ]) as [$op, $a, $b, $to] |

    # Do op
    if $op == 1 then
      .s[$to] = $a + $b
    else
      .s[$to] = $a * $b
    end

    # Step forward
    | .c += 4
  )

  ## SELECT CONDITION
  | select(.s[0] == 19690720)
)

# Output noun * 100 + verb
| .args[0] * 100 + .args[1]
