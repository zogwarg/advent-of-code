#!/usr/bin/env jq -n -R -f

reduce(
  ( inputs | [scan("\\d+ [A-Z]+") /" " | .[0] |= tonumber] | reverse),
  [[1,"ORE"]]
) as $row ({}; $row[0][1] as $k |
  .[$k].out  = $row[0][0] | .r[$k] = 0    |
  .[$k].from = ( $row[1:] | map(reverse))
) |

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

# Output ORE needed for 1 FUEL
produce( "FUEL" ; 1 ).ORE.need
