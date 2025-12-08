#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

#            Get X-Y-Z coordinates     #
[ inputs | [ scan("\\d+")|tonumber ] ] |

last(label $out |

foreach (
  debug("Getting all combinations.")            |
  [ . | combinations(2) | select(first < last)] |
  debug(["Number of combinations", length])     | debug("Sorting..") |
  sort_by(transpose|map(pow(first-last;2))|add) | debug(".")[]
  # Sorted by pairwise distance,                # Until last         #
) as [$a,$b] (
  { circuits: { #        Mappings of boxes to        #
      to_idx: ( #          Circuit group idx         #
        [ to_entries[] | {"\(.value)":.key } ] | add
      ),
      to_box: map([.]),
      groups: length    # Number of disctinct groups #
    }
  };

  if .circuits.groups <= 1 then break $out end |

  ( [ .circuits.to_idx["\($a,$b)"] ]   #    Groups     #
    | unique | [ . - [.[0]], .[0]  ]   # to update and #
  )     as     [ $update   , $min  ] | #    target     #

  reduce $update[] as $u (.;
    .circuits.to_idx["\(.circuits.to_box[$u][])"] = $min |
    .circuits.to_box[$min] += .circuits.to_box[$u]       |
    .circuits.groups -= 1
  )

  | .last = [$a[0],$b[0]]
) # Last connected pair #

) | .last | first * last
