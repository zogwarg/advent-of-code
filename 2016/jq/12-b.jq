#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Get program
[ inputs / " " | .[1:][] |= if tonumber? // false then tonumber else . end ] |

# Recompiling asssembly into more efficient instructions
# Detecting            [inc a  , dec b  , jnz b -2]
# And subtituting with [inc a b, cpy 0 b, jnz b -2]
reduce (
  [.[]|[.[0],.[-1]]] | indices([["jnz",-2]]) | .[]
) as $i (.;
  .[$i][1] as $dec |

  if .[$i-2][0] == "inc" and .[$i-1] == ["dec",$dec] then
    .[$i-2] += [$dec] |
    .[$i-1] = ["cpy",0,$dec]
  end
) |

{
  asmb: .,
  i: 0,
  # Initializing c register at 1
  regs: {c:1}
} |

until(.asmb[.i] | not;
  def get_value($x):
    if $x | tonumber? // false then $x | tonumber
    else .regs[$x] // 0 end
  ;
  def get_inc($x): if $x then get_value($x) else 1 end;

 .asmb[.i] as [$op, $a, $b] |

  if $op == "cpy" then
    .regs[$b] = get_value($a) | .i +=1
  # Enhanced inc op, increasing by 1 or value at "$b"
  elif $op == "inc" then
    .regs[$a] += get_inc($b) | .i += 1
  elif $op == "dec" then
    .regs[$a] -= 1 | .i += 1
  elif $op == "jnz" and get_value($a) != 0 then
    .i += get_value($b)
  else
    .i += 1
  end
)

# Output final value in register a
| .regs.a
