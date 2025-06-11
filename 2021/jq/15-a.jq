#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

#───────────────────────────── Get risk map ─────────────────────────#
[ inputs/"" | map(tonumber) ] | . as $X | [.,.[0]|length] as [$H,$W] |

{ q: [{ p: [0,0], r: 0 }], r: { "[0,0]": 0 } } | until(isempty(.q[]);
  (.q|min_by(.r)) as {$p,$r} | .q = .q - [{$p,$r}] |
  reduce (                                 #═════════════════════════#
    ( $p                                   #                         #
      | (.[0] += (1,-1)), (.[1] += (1,-1)) #     Dijikstra Search    #
      | select(.[0] | . >= 0 and . < $W )  #                         #
      | select(.[1] | . >= 0 and . < $H )  #═════════════════════════#
    ) as $d
    | [ $d, ($r + $X[$d[1]][$d[0]]), (.r["\($d)"] // 1e6) ]
    | select(.[1] < .[2])
  ) as [$p, $r] (.; .r["\($p)"] = $r | .q += [{$p,$r}] )
)

| .r["\([$W,$H| .-1])"] # Lowest possible risk in lower right corner #
