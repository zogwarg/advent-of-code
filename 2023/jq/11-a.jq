#!/usr/bin/env jq -n -R -f

# Get inputs
[ inputs / "" ] |

# Get expanded grid
[
  # Double rows that are all "."
  [ .[] | if [.[] == "."] | all then .,. else . end ]
  # Transpose
  | transpose
  # Double all columns that are all "."
  | [ .[] | if [.[] == "."] | all then .,. else . end ]
  # Transpose back
  | transpose[] | add
  # Get single string grid, and W x H dimensions
] | ( [add, (.[0]|length), (length)] ) as [$grid, $w,$h] |

# Get distance between two points
# (by flat index)
def distance($i1;$i2):
  def get_xy($i): ($i % $w) as $x | ($i - $x | . / $w) as $y | [$x, $y] ;
  [ get_xy($i1), get_xy($i2)] | transpose | map(.[0] - .[-1]| abs ) | add
;

[
  # For all pairs of galaxies
  $grid | indices("#") | combinations(2) | select(.[0] < .[1]) |
  # Compute distance
  distance(.[0];.[1])
  # Output total pairwise distance
] | add
