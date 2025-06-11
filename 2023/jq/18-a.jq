#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce (
  # Produce stream of the vertices, for the position of the center
  foreach (
    # Get inputs as stream of directions = ["R", 5]
    inputs | scan("^(.) (\\d+)") | .[1] |= tonumber
  ) as $dir ([0,0];
    if   $dir[0] == "R" then .[0] += $dir[1]
    elif $dir[0] == "D" then .[1] += $dir[1]
    elif $dir[0] == "L" then .[0] -= $dir[1]
    elif $dir[0] == "U" then .[1] -= $dir[1]
    end
  )
  # Add up total area enclosed by path of center
  # And up the are of the perimeter, perimeter * 1/2 + 1
) as [$x, $y] ( #
  {prev: [0,0], area: 0, perimeter_area: 1  };

  # Adds positve rectangles
  # Removes negative rectangles
  .area += ( $x - .prev[0] ) * $y |

  # Either Δx or Δy is 0, so this is safe
  .perimeter_area += (($x - .prev[0]) + ($y - .prev[1]) | abs) / 2 |

  # Keep current position for next vertex
  .prev = [$x, $y]
)

# Output total area
| ( .area | abs ) + .perimeter_area
