#!/usr/bin/env jq -n -R -f

{
  grid: [inputs / ""],          # Parse inputs to grid
  beams: [{x:0,y:0,dx:1,dy:0}], # Start with beam in top left, heading right
  done: {}                      # Track visits at a location for a direction
} |

.h = (.grid   |length) | # Height of grid
.w = (.grid[0]|length) | # Width  of grid

# Pop beam from propgation list
until (.beams == []; .beams[0] as {$x,$y,$dx,$dy} | del(.beams[0]) |

  # If beam falls outside the grid, or has been done before
  # We let it die without spawning new beams
  if $x < 0 or $x >= .w or $y < 0 or $y >= .h or .done[[$x,$y,$dx,$dy]|join(",")] then
    .
  else
    # Otherwise we mark it as done, and prepare the, direction of new beam
    # Depending which "/" - "\" - "." - "|" - "-" is on the current square
    .done[[$x,$y,$dx,$dy]|join(",")] = true |
    {
      "1,0,\\":[ 0, 1],  "1,0,/":[ 0,-1],  "1,0,|":[ 0, 2],  "1,0,-":[ 1, 0],  "1,0,.":[ 1, 0],
     "-1,0,\\":[ 0,-1], "-1,0,/":[ 0, 1], "-1,0,|":[ 0, 2], "-1,0,-":[-1, 0], "-1,0,.":[-1, 0],
      "0,1,\\":[ 1, 0],  "0,1,/":[-1, 0],  "0,1,|":[ 0, 1],  "0,1,-":[ 2, 0],  "0,1,.":[ 0, 1],
     "0,-1,\\":[-1, 0], "0,-1,/":[ 1, 0], "0,-1,|":[ 0,-1], "0,-1,-":[ 2, 0], "0,-1,.":[ 0,-1]
    }[[$dx,$dy, .grid[$y][$x]]|join(",")] as [$dx,$dy] |

    # Adding one or two new beams to the list,
    .beams += [
      {
        dx: (if $dx == 2 then (1,-1) else $dx end),
        dy: (if $dy == 2 then (1,-1) else $dy end)
      } |  .x = ( $x + .dx )  |  .y = ( $y + .dy )
    ]
  end
)

# Output number of unique visited squares
| .done | [ keys[] / "," | .[:2] ] | unique | length
