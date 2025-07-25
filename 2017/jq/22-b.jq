#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / "" ] as $grid |
($grid   | length/2 |floor) as $H |
($grid[0]| length/2 |floor) as $W |

# Painfully slow, but too lazy to find a better way
reduce range(10000000) as $_ (
  { # Initilize state as with sparse representation
    state:
    (
      [
        $grid
      | to_entries[] | ( .key - $H ) as $j | .value
      | to_entries[] | ( .key - $W ) as $i | .value
      | select(. == "#") | {"\([$i,$j])": 0 }
      ] | add # 0=infected, 1=weakened, 2=flagged
    ),
    pos: [ 0, 0], # Current position
    dir: [ 0,-1], # Current direction
    ifc: 0        # Infections counter
  };
  if .state["\(.pos)"] == 0 then
    # Turn right
    .dir = {
      "[0,-1]":[1, 0],"[0,1]":[-1,0],
      "[-1,0]":[0,-1],"[1,0]":[ 0,1]
    }["\(.dir)"] |
    # Flag node
    .state["\(.pos)"] = 2
  elif .state["\(.pos)"] == 1 then
    # No turns
    # ---
    # Infect node
    .state["\(.pos)"] = 0 | .ifc += 1
  elif .state["\(.pos)"] == 2 then
    # Reverse
    .dir = {
      "[0,-1]":[0,1],"[0,1]":[ 0,-1],
      "[-1,0]":[1,0],"[1,0]":[-1, 0]
    }["\(.dir)"] |
    # Clean node
    del(.state["\(.pos)"])
  else
    # Turn left
    .dir = {
      "[0,-1]":[-1,0],"[0,1]":[1, 0],
      "[-1,0]":[ 0,1],"[1,0]":[0,-1]
    }["\(.dir)"] |
    # Weaken node
    .state["\(.pos)"] = 1
  end |
  # Move forwards
  .pos = ([.pos,.dir]|transpose|map(add))

  | debug(if $_ % 1000 == 0 then {$_} else empty end)
)

# Output number of infections
| .ifc
