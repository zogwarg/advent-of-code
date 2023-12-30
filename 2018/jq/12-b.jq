#!/usr/bin/env jq -n -sR -f

# Utility function
def assert($stmt; $msg): if $stmt == false then $msg | halt_error end;

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

def update_state:
  ["." + .[0] , .[1] + "."] as [$left, $right] |
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
;

# Do 500 game-ticks
reduce range(500) as $i (
  ["....",$state];
  update_state
) |

[ # Check that growth has stabilized to be linear
  foreach range(50) as $i (
    .;
    update_state;
    map(. / "") | .[0] |= reverse | map(indices("#"))
    | .[0] |= [ .[] * -1 | . - 1 ]
    | add | add
  )
] as $counts |

assert(
  [range(0;49) as $i | $counts[$i+1] - $counts[$i]]|unique|length == 1;
  "Difference between two generations should be stable in the long run"
)

# Output projected linear growth
| $counts[1] + (50e9 - 502) * ($counts[1]-$counts[0])
