#!/usr/bin/env jq -n -f

# Get favorite number
inputs  as $fav  |

{
  seen: {"1,1":0},
  search: [{pos:[1,1],d:0}]
} |
# BFS search, stop when depth is 50
until (isempty(.search[] | select(.d < 50));

  # Is input square open?
  def is_open:
    . as [$x, $y] # For x,y coordinates
    | {
        v: ($x*$x + 3*$x + 2*$x*$y + $y + $y*$y + $fav),
        b: 0
      }
    # Count bits
    | until (.v ==0;
        .v -= pow(2;.v|logb) | .b += 1
      )
    # If even yes, otherwise no
    | .b % 2 == 0
  ;

  .search[0] as $curr | .search |= .[1:] | .seen as $seen |
  reduce (
    $curr.pos
    | (.[0] -= 1),
      (.[0] += 1),
      (.[1] -= 1),
      (.[1] += 1)
    | select(.[0] >= 0 and .[1] >= 0)
    | select(is_open and ($seen[join(",")]|not))
    | {pos: ., d: ($curr.d + 1)}
  ) as $new (.;
    .search += [$new] |
    .seen[$new.pos|join(",")] = $new.d
  )
)

# Output total reached squares
| .seen | keys | length
