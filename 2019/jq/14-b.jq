#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce(
  ( inputs | [scan("\\d+ [A-Z]+") /" " | .[0] |= tonumber] | reverse),
  [[1,"ORE"]]
) as $row ({}; $row[0][1] as $k |
  .[$k].out  = $row[0][0] | .r[$k] = 0    |
  .[$k].from = ( $row[1:] | map(reverse))
) | . as $formulas |

def produce($m; $need):
  .[$m] as { $from, $out } | reduce $from[] as [$ing, $in] (.;

    # Each ingredient must be in excess, but make sure to use remains
    (($need / $out | ceil * $in ) - .r[$ing]) as $need |# of previous
    .[$ing].need += $need | # reactions, and  only increase as needed

    (($need / .[$ing].out | ceil) * .[$ing].out - $need) as $remain |
     .r[$ing] = $remain   | # Set next remainder
    produce($ing; $need)    # Produce needed ingredients recursively
  )
;

first(
  range(50) as $i |
  produce( "FUEL" ; pow(2;$i)).ORE.need | select(. > 1e12 ) |
  [ pow(2;$i-1), pow(2;$i), $i ]
) as [ $low, $high, $i ] |

nth(
  $i - 1;
  [ $low, $high ] | recurse(
  . as [$a, $b] | (add / 2) as $mid |
  $formulas | produce( "FUEL" ; $mid).ORE.need < 1e12
  | if . then [$mid, $b] else [$a, $mid] end
  ) # Return lower bound of binary search
) | .[0]
