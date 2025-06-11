#!/bin/sh
# \
exec jq -n -f "$0" "$@"

input | . as $in |

# Math time!
# Find lower root of, lower bounding square
sqrt | floor as $r_sqr |

# Distance to lower bounding square
($in - $r_sqr * $r_sqr) as $d |

# Positions of even squares = (0,1) + .5 sqr * (-1,+1)
if $r_sqr % 2 == 0 then
  [
    0 - ( .5 * $r_sqr - 1),
    1 + (.5 * $r_sqr - 1)
  ] |
  if $d == 0 then
    .
  elif $d <= $r_sqr + 1 then
    # One square left + down
    .[0] -= 1 |
    .[1] -= ($d - 1)
  else
    # One square left + down full $r_sqr
    # Right for remainder
    .[0] += ($d - 1 - $r_sqr - 1) |
    .[1] -= $r_sqr
  end
# Positions of odd squares = (0,0) + .5 sqr * (+1,-1)
else
  [
    0 + ( .5 * $r_sqr - 0.5 ),
    0 - ( .5 * $r_sqr - 0.5 )
  ] |
  if $d == 0 then
    .
  elif $d <= $r_sqr + 1 then
    # One square right + up
    .[0] += 1 |
    .[1] += ($d - 1)
  else
    # One square left + up full $r_sqr
    # Left for remainder
    .[0] -= ($d - 1 - $r_sqr - 1) |
    .[1] += $r_sqr
  end
end

# Output Manhattan distance
| map(abs) | add