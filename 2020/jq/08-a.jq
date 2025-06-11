#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / " " | .[1] |= tonumber ] as $prog |

# Iterate trhough program until out-of-bounds or looped
{i: 0, acc: 0, s: []} | until (.i as $i | ($prog[$i] | not) or (.s | contains([$i]));
  .i as $i |
  if $prog[$i][0] == "acc" then
    .acc += $prog[$i][1] | .i += 1
  elif $prog[$i][0] == "jmp" then
    .i += $prog[$i][1]
  else
    .i += 1
  end | .s += [$i]
)

# Output acc
| .acc