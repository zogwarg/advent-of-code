#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Parse inputs to grid
[ inputs / "" | map(tonumber) ] as $grid |

# Get grid dimensions
( $grid[0] | length ) as $W |
( $grid    | length ) as $H |

# Produce map of elements that reference their positions
# Eg 1x1 -> [[{i:0,j:0}]]
[ range($H) as $j | [ range($W) as $i | {$i,$j} ]] |

# Set the first (starting) element as having:
# vertical   cost        .v  = 0
# horizontal cost        .h  = 0
# Debug iter counter     .c  = 0
# vertical   search done .vd = null
# horizontal search done .hd = null
.[0][0] = {i: 0, j:0, v: 0, h: 0, c:0} |

# Each sub list are the increments required.
# "Lowest"  = ±[1,2,3,4]
# "Highest" = ±[1,2,3,4,5,6,7,8,9,10]
[ range(4;11) | [ range(1;.+1) ] | . , map(. * -1) ] as $delta |

# Until vertical and horizontal search is done for all squares
until(all(.[][]; .hd and .vd); debug("Iter = \(.[0][0].c)") |

  # Get all nodes for which new search should be done
  [ .[][] | select(.v and (.vd | not )) ] as $v |
  [ .[][] | select(.h and (.hd | not )) ] as $h |

  # Generate the list of squares, reachables from these
  # Nodes, with associated vertical or horizontal cost
  [
    $delta[] as $dj | $v[] | {i, j, v} | . as {$i,$j,$v} |
    .j = ( $j + $dj[-1] ) | select(.j >= 0 and .j < $H)  |
    .h = ([ $grid[ $j + $dj[] ][$i] ] | add + $v )
  ] as $nv |
  [
    $delta[] as $di | $h[] | {i, j, h} | . as {$i,$j,$h} |
    .i = ( $i + $di[-1] ) | select(.i >= 0 and .i < $W)  |
    .v = ([ $grid[$j][ $i + $di[] ] ] | add + $h )
  ] as $nh |

  # Update cost and mark as search to be done if value
  # Is new minimum, (starting value = "Infinite")
  reduce $nv[] as {$i,$j,$h} (.;
    .[$j][$i] |= if (.h|not) or .h > $h then .h = $h | del(.hd) end
  ) |
  reduce $nh[] as {$i,$j,$v} (.;
    .[$j][$i] |= if (.v|not) or .v > $v then .v = $v | del(.vd) end
  ) |

  # If search node was not updated with lower value
  # Mark search as being done
  reduce $v[] as {$i,$j,$v} (.;
    if $v <= .[$j][$i].v then .[$j][$i].vd = true end
  ) | reduce $h[] as {$i,$j,$h} (.;
    if $h <= .[$j][$i].h then .[$j][$i].hd = true end
  )

  # Debug counter
  | .[0][0].c += 1
)

# Lowest cost for final square
| .[-1][-1] | [ .h, .v ] | min
