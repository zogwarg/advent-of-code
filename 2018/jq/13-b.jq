#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

[ # Parse input as tracks
  inputs / ""
] as $tracks |

[ # Get all carts, with their positions
  $tracks
| to_entries[] | .key as $j | .value
| to_entries[] | .key as $i | .value
| select(. | inside("<>^v"))
| [[$j,$i], {"<":[-1,0],">":[1,0],"^":[0,-1],"v":[0,1]}[.], 0]
] as $carts |

{
  $carts
}
| # Until only one cart, update the cart positions
until(.carts|length==1;
  .collisions = [] |
  reduce .carts[] as $cart (
    .;
    .carts = .carts - [$cart] |
    $cart as [[$j,$i],$dir,$st] |

    # Skip collided carts
    if .collisions | contains([[$i,$j]]) then . else

      ( # Update direction
        if $tracks[$j][$i] == "+" then
          {
            "[[-1,0],0]": [[ 0, 1],1],
            "[[-1,0],1]": [[-1, 0],2],
            "[[-1,0],2]": [[ 0,-1],0],
            "[[0,-1],0]": [[-1, 0],1],
            "[[0,-1],1]": [[ 0,-1],2],
            "[[0,-1],2]": [[ 1, 0],0],
             "[[0,1],0]": [[ 1, 0],1],
             "[[0,1],1]": [[ 0, 1],2],
             "[[0,1],2]": [[-1, 0],0],
             "[[1,0],0]": [[ 0,-1],1],
             "[[1,0],1]": [[ 1, 0],2],
             "[[1,0],2]": [[ 0, 1],0]
          }["\([$dir,$st])"]
        elif $tracks[$j][$i] | inside("\\/") then
          {
            "[[-1,0],\"\\\\\"]": [[ 0,-1],$st],
               "[[-1,0],\"/\"]": [[ 0, 1],$st],
            "[[0,-1],\"\\\\\"]": [[-1, 0],$st],
               "[[0,-1],\"/\"]": [[ 1, 0],$st],
             "[[0,1],\"\\\\\"]": [[ 1, 0],$st],
                "[[0,1],\"/\"]": [[-1, 0],$st],
             "[[1,0],\"\\\\\"]": [[ 0, 1],$st],
                "[[1,0],\"/\"]": [[ 0,-1],$st]
          }["\([$dir,$tracks[$j][$i]])"]
        else [$dir,$st] end
      ) as [$dir,$st] |

      # Update position
      ( $j + $dir[1] ) as $j | ($i + $dir[0]) as $i |

      # Detect collision
      ( [.carts[][0]] | index([[$j,$i]])) as $k |
      if $k then
        # Remove cart collided with, from list
        .collisions += [[$i,$j]] | del(.carts[$k])
      else
        # Add back to list if none
        .carts += [[[$j,$i],$dir,$st]]
      end
    end
  ) | .carts |= sort
)

# Output coordinates of last cart
| .carts[0][0] | reverse | join(",")
