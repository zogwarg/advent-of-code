#!/usr/bin/env jq -n -R -f

# Take array and produce groups of $n
def group_of($n):
  ( length / $n ) as $l |
  . as $arr |
  range($l) | $arr[.*$n:.*$n+$n]
;

# Get list of called numbers
(input / "," | map(tonumber)) as $nums |

# Get all boards
[[ inputs | [ match("\\d+";"g").string | tonumber ] | select(length > 0)] | group_of(5) ] as $boards |

# Get number and first winning board,
reduce $nums[] as $num ({b: $boards,w: []};
  .n = $num |
  .b[][][] |=  ( if . == $num then "x" else . end ) |
  .win = [
    .b[] | select( [ ( .[] , ( range(5) as $i | [ .[][$i] ] ) ) == ["x","x","x","x","x"] ] | any )
  ] |
  # Remove winning boards
  .b = (.b - .win ) |
  # Keep all win events, with n and board state
  .w = ( .w + [[.n, .win]] )
)

# Get last win
| last(.w[] | select(.[1][])) as [$n,[$win]]

# Output n * score
| $n * ( [$win[][] | numbers] | add)
