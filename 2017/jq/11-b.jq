#!/usr/bin/env jq -n -R -f

reduce(
  inputs / "," | .[]
) as $step (     # Using cube coordinates (plane x + y + z = 0)
  {x:0,y:0,z:0}; # To represent the current location in hex grid
  .x += {"n": 0,"s": 0,"ne": 1,"sw":-1,"nw":-1,"se": 1}[$step] |
  .y += {"n": 1,"s":-1,"ne": 0,"sw": 0,"nw": 1,"se":-1}[$step] |
  .z += {"n":-1,"s": 1,"ne":-1,"sw": 1,"nw": 0,"se": 0}[$step] |
  .max = ([.max, ([.x,.y,.z|abs] | add/2)] | max)
)

# Output the maximum distance
# Along the path
| .max
