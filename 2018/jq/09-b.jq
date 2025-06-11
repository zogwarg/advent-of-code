#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ # Scan players, and last marble
  inputs | scan("\\d+") | tonumber
] as [$players, $last] |

# Foreach marble, starting with circle [0]
reduce range(1;$last*100+1) as $mb ({c:[0],p:0};
  # Percentage debug since super slow in JQ
  ( if $mb / $last > .p then .p += 1 | ({p}|debug) as $d | . else . end ) |

  if $mb % 23 != 0 then
     # Shift circle clockwise so top position is +1 item after last added item
    .c = .c[1:] + .c[0:1] + [ $mb ]  # Where we can then append current marble
  else
    .s[$mb % $players] += ($mb + .c[-8]) | # Add Circle(-7)+MB to player score
    .c = .c[-6:] + .c[:-8] + .c[-7:-6] # Pop Circle(-7) and S(-6), for nxt ele
  end
) | .s | max
