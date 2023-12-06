#!/usr/bin/env jq -n -R -f

# Distance function
def dist($x; $y): [ (.[0] - $x ), .[1] - $y ] | map(abs) | add;

# Get all coords
[ inputs | [scan("\\d+")|tonumber]] as $coords |

# Get bounding box
[
  ([$coords[][0]] | min, max),
  ([$coords[][1]] | min, max)
] as [$xmin, $xmax, $ymin, $ymax] |

## Naive loop instead of good math
reduce (
  range($xmin; $xmax+1) as $x |
  range($ymin; $ymax+1) as $y |
  [$x, $y]
) as [$x, $y] ({};
  (
    $coords
    | [ .[] | [ . , dist($x;$y) ] ]
    | sort_by(.[1])
    | if (.[0][1] == .[1][1]) then "x" else .[0][0] | join(",")  end
  ) as $near |
  # If border is closest to a point, then the point has infinite area
  if ( $x == $xmin or $y == $ymin or $x == $xmax or $y == $ymax) then
    .[$near] = "+Inf"
  # Otherwise increase area for point
  elif .[$near] != "+Inf" then
    .[$near] += 1
  else
    .
  end
)

# Output largest finite area
| [ .. | numbers ] | max
