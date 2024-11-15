#!/usr/bin/env jq -n -R -f

# Scanning for all nanobots, assemble !
[ inputs | [ scan("-?\\d+")|tonumber ]]
| max_by(.[-1]) as $S | # The strongest

map(# Collect all nanobots within range
  [.[0:3],$S[0:3]] | transpose #[rX,sX]
  | map( .[0] - .[1] | abs ) #  abs(dX)
  | select(add <= $S[3]) # man_dst < sR
) | length               # Output count
