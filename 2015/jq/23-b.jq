#!/usr/bin/env jq -n -R -f

[ # Parse inputs, as:
  inputs | [
    scan("^..."),                   # instruction
    ( scan(" [ab]")[1:] // null ),  # register
    ( scan("[-+]?\\d+") | tonumber) # offset
  ]
] as $prgm |

{
  $prgm,
  i: 0,
  regs: {a: 1} # Set initial value of a as 1
} |

until(.prgm[.i]|not;
  .prgm[.i] as [$op, $x, $n] |
    if $op == "hlf" then
    .regs[$x] /= 2 |
    .i += 1
  elif $op == "inc" then
    .regs[$x] += 1 |
    .i += 1
  elif $op == "jie" then
    if .regs[$x] % 2 == 0 then
      .i += $n
    else
      .i += 1
    end
  elif $op == "jio" then
    if .regs[$x] == 1 then
      .i += $n
    else
      .i += 1
    end
  elif $op == "jmp" then
    .i += $n
  elif $op == "tpl" then
    .regs[$x] *= 3 |
    .i += 1
  else "Unexpected op \($op)" | halt_error end
)

# Output value in b register after execution
| .regs.b
