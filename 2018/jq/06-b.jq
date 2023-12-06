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
) as [$x, $y] (0;
  # +1 if total distance is less than 10_000
  if $coords | map(dist($x;$y)) | add < 10000 then . + 1 else . end
)
