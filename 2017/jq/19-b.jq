#!/usr/bin/env jq -n -rR -f

[ inputs / "" ] as $grid |

{
  pos: [$grid[0]|index("|"),0], # Start at top row
  dir: [0,1],                   # Going down
  stp: 0                        # Counting steps
} |
until (.done;

  # Walk straight to intersection, or end
  until ($grid[.pos[1]][.pos[0]] | . == "+" or . == " ";
    # Counting steps along the way
    .stp += 1 | .pos[0] += .dir[0] | .pos[1] += .dir[1]
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
      $new_dir[] as $d | .pos[0] += $d[0] | .pos[1] += $d[1] | .stp += 1 |
      select($grid[.pos[1]][.pos[0]] != " ") | .dir = $d
    )
  end
)

# Output steps
| .stp
