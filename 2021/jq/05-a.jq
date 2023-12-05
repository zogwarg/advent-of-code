#!/usr/bin/env jq -n -R -f
def is_v: .[0] == .[2];
def is_h: .[1] == .[3];

# Only consider horizontal and vertical lines
reduce ( inputs | [ match("\\d+";"g").string | tonumber ] | select(is_v or is_h)) as $line (
  {p:{}};
  ( [ $line[0], $line[2] ] | sort ) as [$x1, $x2] |
  ( [ $line[1], $line[3]] | sort ) as [$y1, $y2] |
  .p[[ [range($x1;$x2+1)], [range($y1;$y2+1)] ] | combinations | join(",") ] += 1
)

# Ouput number of overlapped points
| [ .p[] | select(. > 1) ] | length
