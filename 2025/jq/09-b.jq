#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs | [ scan("\\d+") | tonumber ]]

| . as $points | length as $L
| ( [ ., .[1:] + .[0:1] ] | transpose ) as $lines |

# Implementing mostly the same method as manual visual solve.
# Shape should roughly be:
#    ┌──────────┐
#   ┌┘          └┐
#  ┌┘            └┐
# ┌┘              └┐
# └─────────────┐  └ Start
# ┌─────────────┘  ┌ End
# └┐              ┌┘
#  └┐            ┌┘
#   └┐          ┌┘
#    └──────────┘

(
  [ $lines | to_entries[] |
    { key, value, w: ( .value | .[0][0] - .[1][0] | abs )  }
  ] | sort_by(.w)[-3:] |
  .[1:] |= sort_by(.key)
) as $widest |

# Assertions that should hold for assumed shape
if $widest[1].key < 0.45 * $L or $widest[1].key > 0.55 * $L or
   $widest[1].w > 1.05 * $widest[2].w or
   $widest[2].w > 1.05 * $widest[1].w or
   $widest[1].w < 25 * $widest[0].w or
   $widest[2].key - $widest[1].key != 2 or
   $lines[$L * 0.25][0][1] < $widest[1].value[0][1] or
   $lines[$L * 0.75][0][1] > $widest[2].value[0][1] or
   any($lines[]; .[0][0] != .[1][0] and .[0][1] != .[1][1])
then "Assumptions about shape not held!" | halt_error end |

[ # Finding maximum height  up  from 1st pivot
  $lines[0:.25*$L][] |
  select(
    .[0][1] == .[1][1] and .[0][0] >= $widest[1].value[1][0]
                       and .[1][0] <= $widest[1].value[1][0]
  )
] as $top |

[ # Finding maximum height down from 2nd pivot
  $lines[.75*$L:][] |
  select(
    .[0][1] == .[1][1] and .[0][0] <= $widest[2].value[0][0]
                       and .[1][0] >= $widest[2].value[0][0]
  )
] as $bottom |

# Assertion of only 1 intersection up and down
if [$top, $bottom | length] | unique != [1]
then "Assumptions about intersections not held!" | halt_error end |

[
  (
    $lines[.25 * $L:$widest[1].key][] |
    select(.[0][1] == .[1][1]) | .[1] | select(
      .[1] <= $top[0][0][1] # Find possible boxes with 1st pivot
    ) | [ ., $widest[1].value[1] ]
  ),
  (
    $lines[$widest[1].key:.75*$L][] |
    select(.[0][1] == .[1][1]) | .[0] | select(
      .[1] >= $top[0][0][1] # Find possible boxes with 2nd pivot
    ) | [ ., $widest[2].value[0] ]
  )
  | transpose | map(first-last|abs+1) | first * last
] | max
