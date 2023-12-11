#!/usr/bin/env jq -n -R -f

[ # Scan players, and last marble
  inputs | scan("\\d+") | tonumber
] as [$players, $last] |

# Foreach marble, starting with circle [0]
reduce range(1;$last+1) as $mb ({c:[0]};
  if $mb % 23 != 0 then
     # Shift circle clockwise so top position is +1 item after last added item
    .c = .c[1:] + .c[0:1] + [ $mb ]  # Where we can then append current marble
  else
    .s[$mb % $players] += ($mb + .c[-8]) | # Add Circle(-7)+MB to player score
    .c = .c[-6:] + .c[:-8] + .c[-7:-6] # Pop Circle(-7) and S(-6), for nxt ele
  end
) | .s | max
