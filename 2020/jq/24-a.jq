#!/usr/bin/env jq -n -R -f

def toHexTile: reduce scan("se|sw|ne|nw|e|w") as $step (
  {x:0,y:0,z:0};  # Using cube coordinates (plane x + y + z = 0)
  .x += {"w": 0,"e": 0,"nw": 1,"se":-1,"sw":-1,"ne": 1}[$step] |
  .y += {"w": 1,"e":-1,"nw": 0,"se": 0,"sw": 1,"ne":-1}[$step] |
  .z += {"w":-1,"e": 1,"nw":-1,"se": 1,"sw": 0,"ne": 0}[$step]
)| [.x,.y,.z];

[ inputs | toHexTile ]
| group_by(.)
| map(length|select(.%2==1))      # How many tiles are flipped #
| length                          #   an odd number of times   #
