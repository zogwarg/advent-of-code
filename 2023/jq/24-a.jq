#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

200000000000000 as $low  |
400000000000000 as $high |

def det2($mat):
  $mat[0][0] * $mat[1][1] - $mat[0][1] * $mat[1][0]
;

def crossInBox($a;$b):
  # Solve for
  # ax + n * adx = ay + m * ady
  # ay + n * ady = by + m * bdy
  $a as [$ax,$ay,$adx,$ady] | $b as [$bx,$by,$bdx,$bdy] |

  det2([[$adx,-$bdx],[$ady,-$bdy]]) as $det |

  if $det == 0 then
    # If determinant is zero, the lines are parallel
    false
  else
    # Solve for n and m
    ( det2([[$bx - $ax,  -$bdx],[$by - $ay,  -$bdy]]) / $det ) as $n |
    ( det2([[$adx     ,$bx-$ax],[$ady     ,$by-$ay]]) / $det ) as $m |

    # Get coordinate of intersection
    [ ($ax + $n * $adx), ($ay + $n * $ady) ] |

    # Only keep points that insersect:
    (
      $m > 0 and $n > 0 and              # In the future,
      .[0] >= $low and .[0] <= $high and # X is within test area
      .[1] >= $low and .[1] <= $high     # Y is within test area
    )
  end
;

[
  inputs               # Parse Inputs:
  | [ scan("-?\\d+") ] # Extract numbers
  | map(tonumber)      # Convert to numeric type
  | [ .[0,1,3,4] ]     # Only keep: x, y, dx, dy
] |

[ # Get all unique pairs, with a future intersection
  combinations(2) # Within test area.
  | select(.[0] < .[1] and crossInBox(.[0];.[1]) )
] | length
