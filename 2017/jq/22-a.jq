#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / "" ] as $grid |
($grid   | length/2 |floor) as $H |
($grid[0]| length/2 |floor) as $W |

reduce range(10000) as $_ (
  { # Initilize state as with sparse representation
    state:
    (
      [
        $grid
      | to_entries[] | ( .key - $H ) as $j | .value
      | to_entries[] | ( .key - $W ) as $i | .value
      | select(. == "#") | {"\([$i,$j])": true }
      ] | add
    ),
    pos: [ 0, 0], # Current position
    dir: [ 0,-1], # Current direction
    ifc: 0        # Infections counter
  };
  if .state["\(.pos)"] then
    # Turn right
    .dir = {
      "[0,-1]":[1, 0],"[0,1]":[-1,0],
      "[-1,0]":[0,-1],"[1,0]":[ 0,1]
    }["\(.dir)"] |
    # Clean node
    del(.state["\(.pos)"])
  else
    # Turn left
    .dir = {
      "[0,-1]":[-1,0],"[0,1]":[1, 0],
      "[-1,0]":[ 0,1],"[1,0]":[0,-1]
    }["\(.dir)"] |
    # Infect node
    .state["\(.pos)"] = true | .ifc += 1
  end |
  # Move forwards
  .pos = ([.pos,.dir]|transpose|map(add))
)

# Output number of infections
| .ifc
