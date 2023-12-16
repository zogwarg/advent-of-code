#!/usr/bin/env jq -n -R -f

[ # Parse inputs, ⬇ lose = negative |  ⬇ 1st letters of names   |   ⬇ Parse number
  inputs | gsub("lose ";"-") | [scan("([A-Z]).+([A-Z])")[], (scan("-?\\d+")|tonumber)]
] |

( # Buld happiness score mapping
  group_by(.[0])
| map({ (.[0][0]): ( map({ (.[1]): .[2] }) | add) })
| add # Eg: {"A": {"B": 30, "C": -12, [...]}, [...]}
) as $happy_score |

# Circle permutations
def circle_perms:
  def perms:
    if length == 1 then . else
    .[] as $c | ( . - [$c] | perms) as $arr | [$c, $arr[]]
    end
  ;
  # Since its a circle, it can always
  # start with the same element
  [.[0]] + (.[1:] | perms) |

  # Appending start to end, and end to start
  # For convenience
  .[-1:] + . + .[0:1]
;

# Part 2:
# Simple edit add neutral ⬇ guest.
( $happy_score | keys + ["Z"]) | [
  # For each seating permutation
  circle_perms | to_entries | . as $circle | .[1:-1] |
  # Compute total change in happiness
  # Default values are 0 for missing entries
  map(
    $happy_score[.value][$circle[.key-1].value] +
    $happy_score[.value][$circle[.key+1].value]
  ) | add
  # Output value for revised optimal seating
] | max
