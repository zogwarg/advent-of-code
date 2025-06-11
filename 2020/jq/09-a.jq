#!/bin/sh
# \
exec jq -n -f "$0" "$@"

25 as $w |

[ inputs ] | first(

  # Sliding window of size w + 1 over inputs
  range(0;length-$w) as $i | .[$i:($i+$w+1)] |

  select( # Checking last element, over every previous sum pair
    .[0:-1] as $prev | [.[-1]] | inside(
      [ $prev | combinations(2) | select(.[0] < .[1]) | add ]
    ) | not
  )
)

# Output first mismatch
| .[-1]
