#!/bin/sh
# \
exec jq -n -f "$0" "$@"

{
  in: input,
  grid: {"0,0": 1},
  pos: [1,0],
  cur: 1,
  dir: "r"
} | until ( .cur > .in;
  # Sum all neighbout boxes
  ([
    .grid[.pos | .[0] += (1,-1,0) | .[1] += (1,-1,0) | join(",")]
  ]|add) as $n |

  # Save value, to grid and current held value
  ( .grid[.pos|join(",")] , .cur ) = $n |

  # Spiral around grid
  if .dir == "r" then
    if .grid[.pos | .[1] += 1 |join(",")] then
      .pos[0] += 1
    else
      .dir = "u" |
      .pos[1] += 1
    end
  elif .dir == "u" then
    if .grid[.pos | .[0] -= 1 |join(",")] then
      .pos[1] += 1
    else
      .dir = "l" |
      .pos[0] -= 1
    end
  elif .dir == "l" then
    if .grid[.pos | .[1] -= 1 |join(",")] then
      .pos[0] -= 1
    else
      .dir = "d" |
      .pos[1] -= 1
    end
  else
    if .grid[.pos | .[0] += 1 |join(",")] then
      .pos[1] -= 1
    else
      .dir = "r" |
      .pos[0] += 1
    end
  end
)

# Output first value greater than input
| .cur