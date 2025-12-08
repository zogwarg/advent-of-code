#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

#            Get X-Y-Z coordinates     #
[ inputs | [ scan("\\d+")|tonumber ] ] |

reduce (
  debug("Getting all combinations.")            |
  [ . | combinations(2) | select(first < last)] |       1000 as $L   |
  debug(["Number of combinations", length])     | debug("Sorting..") |
  sort_by(transpose|map(pow(first-last;2))|add) | debug(".")[0:$L][]
  # Sorted by pairwise distance,                # First 1000 closest #
) as [$a,$b] (
  { circuits: { #        Mappings of boxes to        #
      to_idx: ( #          Circuit group idx         #
        [ to_entries[] | {"\(.value)":.key } ] | add
      ),
      to_box: map([.])
    }
  };
  ( [ .circuits.to_idx["\($a,$b)"] ]   #    Groups     #
    | unique | [ . - [.[0]], .[0]  ]   # to update and #
  )     as     [ $update   , $min  ] | #    target     #
  reduce $update[] as $u (.;
    .circuits.to_idx["\(.circuits.to_box[$u][])"] = $min |
    .circuits.to_box[$min] += .circuits.to_box[$u]
  )
)

| .circuits.to_box | map(length) | sort_by(-.) as [$a,$b,$c]  #
| $a * $b * $c     # Output product of the 3 largest circuits #
