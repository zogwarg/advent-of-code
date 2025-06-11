#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

[ inputs / "" ] as $grid |

{
  pos: [$grid[0]|index("|"),0], # Start at top row
  dir: [0,1],                   # Going down
  str: ""                       # To collect string
} |
until (.done;

  # Walk straight to intersection, or end
  until ($grid[.pos[1]][.pos[0]] | . == "+" or . == " ";
    if $grid[.pos[1]][.pos[0]] | test("[A-Z]") then
      # Collect letters on the way
      .str += $grid[.pos[1]][.pos[0]]
    end
    | .pos[0] += .dir[0] | .pos[1] += .dir[1]
  ) |

  # Select and take correct turn at intersection
  if $grid[.pos[1]][.pos[0]] == " " then .done = true else
    {
       "[0,1]": [[ 1, 0],[-1, 0]],
      "[0,-1]": [[ 1, 0],[-1, 0]],
       "[1,0]": [[ 0,-1],[ 0, 1]],
      "[-1,0]": [[ 0,-1],[ 0, 1]]
    }["\(.dir)"] as $new_dir |
    first(
      $new_dir[] as $d | .pos[0] += $d[0] | .pos[1] += $d[1] |
      select($grid[.pos[1]][.pos[0]] != " ") | .dir = $d
    )
  end
)

# Output string
| .str
