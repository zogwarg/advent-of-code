#!/usr/bin/env jq -n -R -f

# Save asteroids to grid |
[ inputs / "" ] as $grid |

reduce (
  # Get the coordinates of all the asteroids
  [($grid[0],$grid) | length ] as [$w,$h] |
  def to_xy: (. % $w) as $x | [$x, (. - $x | . / $h)];
  ($grid|map(add)|add|indices("#")|map(to_xy)) |

  # Testing all pairs of asteroids once
  combinations(2) | select(.[0] < .[1])
) as $pair ({};

  # Calculate smallest possible step on grids, for delta(x,y) between two points
  def delta_to_inc($delta):
    # Greatest common factor: with $a > $b
    def gcf($a;$b): ( $a % $b ) as $r | if $r == 0 then $b else gcf($b; $r) end;

    # Sanitize inputs for gcf
    if   $delta[0] <  0 then delta_to_inc([-$delta[0],$delta[1]]) | [-.[0],.[1]]
    elif $delta[1] <  0 then delta_to_inc([$delta[0],-$delta[1]]) | [.[0],-.[1]]
    elif $delta[0] == 0 then [0, $delta[1]/($delta[1]|abs)]
    elif $delta[1] == 0 then [$delta[0]/($delta[0]|abs), 0]

    # We have a postive fraction,  we can reduce to its canonical form
    else gcf($delta[1];$delta[0]) as $gcf | $delta | map(. / $gcf) end
  ;

  delta_to_inc($pair|transpose|map(.[1]-.[0])) as $inc |

  if (
  (
    [ # Between pair check points on the grid,
      [range($pair[0][0];$pair[1][0];$inc[0])],
      [range($pair[0][1];$pair[1][1];$inc[1])]
    ] | transpose |

    # Fix degeneracy caused by: Δ(x) or Δ(y) == 0
    if   .[0][0] == null then .[][0] = $pair[0][0]
    elif .[0][1] == null then .[][1] = $pair[0][1]
    else . end
  ) |
    length == 1 or # Only range_(0) is on grid
    all( .[1:][]| $grid[.[1]][.[0]]; . != "#")
    # All other points should not be asteroids
  ) then
      # Add pair to each-other's visible list
     .v[$pair[0]|join(",")] += [[$pair[1],[ $inc[0], $inc[1]]]] |
     .v[$pair[1]|join(",")] += [[$pair[0],[-$inc[0],-$inc[1]]]]
  else .
      # Add pair to each-other's hidden l
     .h[$pair[0]|join(",")] += [[$pair[1],[ $inc[0], $inc[1]]]] |
     .h[$pair[1]|join(",")] += [[$pair[0],[-$inc[0],-$inc[1]]]]
  end
) |

# Find the station like before, but keep the location string
( .v | to_entries | max_by(.value|length).key ) as $station |


[ .v[$station][], .h[$station][] ]

| group_by(.[1])   # Group stations by direction: increment
| sort_by(.[0][1]| # Order groups by U, R, D, L using atan2
  map(if isnormal then . else 0 end) | # Fix -0 non-normals
  if .[0] >= -0 then
    atan2(.[0];-.[1])          # -> Range [ 0  , Pi  ]
  else
    6.2832 + atan2(.[0];-.[1]) # -> Range [ Pi , Tau ]
  end
)

# Along each axis,  sort asteroids  by order  of zapping
| map(sort_by([ .[0][0] * .[1][0], .[0][1] * .[1][1] ]))

# Transposing round-robins  between  the ordered groups
| nth(199; transpose[][][0] | arrays) # Selection 200th

# Output X*100 + Y
| .[0] * 100 + .[1]