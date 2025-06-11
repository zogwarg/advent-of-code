#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / " " ] as $prgm |


{ $prgm, l: ($prgm|length), i: 0, regs: {},out:null,rcv:null} |
until ((.prgm[.i]|not) or .rcv;
  .prgm[.i] as [$op, $a, $b] |

  def get_value($x):
    if $x | tonumber? // false then
      $x | tonumber
    else
      .regs[$x] // 0
    end
  ;

  if $op == "snd" then
    .out = get_value($a) | .i += 1
  elif $op == "set" then
    .regs[$a] = get_value($b) | .i += 1
  elif $op == "add" then
    .regs[$a] = (.regs[$a]//0) + get_value($b) | .i += 1
  elif $op == "mul" then
    .regs[$a] = (.regs[$a]//0) * get_value($b) | .i += 1
  elif $op == "mod" then
    .regs[$a] = (.regs[$a]//0) % get_value($b) | .i += 1
  elif $op == "rcv" then
    if get_value($a) != 0 then
      .rcv = .out
    end | .i += 1
  elif $op == "jgz" then
    if get_value($a) > 0 then
      .i += get_value($b)
    else
      .i += 1
    end
  end
)

# Output first recovered frequency
| .rcv
