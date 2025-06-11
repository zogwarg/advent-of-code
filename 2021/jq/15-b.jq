#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

#───────────────────────────── Get risk map ─────────────────────────#
[ inputs/"" | map(tonumber) ] | . as $X | [.,.[0]|length] as [$H,$W] |

def X(p):                 #                         #
  $X[p[1]%$H][p[0]%$W]    #                         #
  + (p[1] / $H | floor)   #    Extended Risk Map    #
  + (p[0] / $W | floor)   #                         #
  | ( . - 1 ) % 9 + 1.    #                         #
;
def R(p): .r[p[1]][p[0]]; # Lowest risk at position #

{ q: [{ p: [0,0], r: 0 }]} | R([0,0]) = 0 |

last(recurse(
  if R([100,100|.*5-1]) or isempty(.q[]) then empty end |
  (.q|min_by(.r)) as {$p,$r} | .q = .q - [{$p,$r}] |
  reduce (                               #═════════════════════════#
    $p                                   #                         #
    | (.[0] += (1,-1)), (.[1] += (1,-1)) #     Dijikstra Search    #
    | select(.[0] | . >= 0 and . < 5*$W) #                         #
    | select(.[1] | . >= 0 and . < 5*$H) #═════════════════════════#
    | [ ., ($r + X(.)) ]
  ) as [$p, $r] (.;
    if $r < ( R($p)//1e6 ) then R($p) = $r | .q += [{$p,$r}] end
  )
))

| R([100,100|.*5-1]) #  Lowest possible risk in lower right corner #
