#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

{
  prgm: [ inputs / " " | .[] |= if tonumber? // false then tonumber end ],
  i: 0
}
| until (.prgm[.i]|not;
  .prgm[.i] as [$op, $a, $b] |

  def get_value($x):
    if $x|type == "number" then
      $x
    else
      .regs[$x] // 0
    end
  ;

  if $op == "set" then
    .regs[$a] = get_value($b) | .i += 1
  elif $op == "sub" then
    .regs[$a] -= get_value($b) | .i += 1
  elif $op == "mul" then
    .regs[$a] *= get_value($b) | .i += 1 | .muls += 1
  elif $op == "jnz" and get_value($a) != 0 then
    .i += get_value($b)
  else
    .i += 1
  end
)

# Output total multiplications
| .muls
