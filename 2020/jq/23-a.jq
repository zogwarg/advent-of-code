#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

[ # Linked list # Curr   # Previous         # Next
  inputs / "" | [ .    , (.[-1:] + .[:-1]), ( .[1:] + .[:1] ) ]
              | transpose[] | { "\(.[0])": .[1:] }
] | (.[0]|keys[0]) as $start | add

# Previous dictionary
| reduce range(2;10) as $i (
    .p["1"] = "9";
    .p["\($i)"] = "\($i-1)"
  )

# Starting cup
| .c = $start |

# Recursively
last(limit(101; recurse(
  [ # Get 3 following cups, + next to re-link list
    [ .[.c][1], . ] | limit(4; recurse([.[1][.[0]][1],.[1]] ))[0]
  ] as [$a,$b,$c,$d] |

  # Stitch current to +next cup
  .[.c][1] = $d | .[$d][0] = .c |

  first( # Get first label ancestor not in picked cups
    [.p[.c],.] | recurse([.[1].p[.[0]],.[1]])[0]
               | select([.]|inside([$a,$b,$c])|not)
  ) as $n | .[$n][1] as $e

  | .[$a][0] = $n | .[$n][1] = $a # Insert picked up cups in
  | .[$c][1] = $e | .[$e][0] = $c # Correct location
  | .c = .[.c][1]                 # Go to next cup
)))

# Get list in order
| [ limit(9;recurse(.c = .[.c][1]).c) ] | index("1") as $i

# Get items after "1"
| .[$i+1:] + .[:$i]
| add