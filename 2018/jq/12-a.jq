#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

# Parse inputs
inputs / "\n\n" |

# Get initial state
(.[0] / ": " | .[1]) as $state |

# Get game-of-plant-life rules
(
  .[1] / "\n"
  | map(. / " => "| select(.[1] == "#") | {(.[0]):.[1]})
  | add
) as $rules |

# Do 20 game-ticks
reduce range(20) as $i (
  ["....",$state]; ["." + .[0] , .[1] + "."] as [$left, $right] |
  [
    [
      ".." + $left[0:3],
      "."  + $left[0:4],
      (range($left|length-4) as $i | $left[$i:$i+5]),
      $left[-4:] + $right[0:1],
      $left[-3:] + $right[0:2] | $rules[.] // "."
    ],
    [
      $left[-2:] + $right[0:3],
      $left[-1:] + $right[0:4],
      (range($right|length-4) as $i | $right[$i:$i+5]),
      $right[-4:] + ".",
      $right[-3:] + ".." | $rules[.] // "."
    ]
  ] | map(add)
)

# Sum of the numbers of pots with plants in them
| map(. / "") | .[0] |= reverse | map(indices("#"))
| .[0] |= [ .[] * -1 | . - 1 ]
| add | add
