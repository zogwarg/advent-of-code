#!/usr/bin/env jq -n -f

25 as $w | [ inputs ] as $inputs |

($inputs | first(
  # Sliding window of size w + 1 over inputs
  range(0;length-$w) as $i | .[$i:($i+$w+1)] |

  select( # Checking last element, over every previous sum pair
    .[0:-1] as $prev | [.[-1]] | inside(
      [ $prev | combinations(2) | select(.[0] < .[1]) | add ]
    ) | not
  )
  | .[-1]
)) as $miss | # Get number from part 1

{
  in: $inputs, # v First list of contiguous sums, for window=2
  sums: ([$inputs[0:-1] , $inputs[1:]] | transpose | map(add)),
  d: 1, # .d = Current "depth" | v Abort if sums size == 0
} | until (.i or (.sums|length) == 0;

  # Get next contiguous sums, by addding the correct number
  # From original list
  .sums = ([.sums[1:], $inputs[0:-.d]] | transpose| map(add))

  | .d += 1                   # Increase depth
  | .i = (.sums|index($miss)) # Check if $miss is in any sums
)

| .in[.i:.i+.d+.1] # Get range that sums to $miss
|  min + max       # Final output
