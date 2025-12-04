#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[  inputs /   ""   ]             | #    Grid    #
[ .[0], . | length ] as [$W, $H] | # Dimensions #

def get_rolls($i; $j): select(.[$i][$j] == "@") | [
    ($i+(-1,0,1)) as $i # 3x3 #
  | ($j+(-1,0,1)) as $j # box # Don't go outside the grid #
  | select( $i >= 0 and $i < $H and $j >= 0 and $j < $W ) #
  | .[$i][$j] | select(. == "@") #    Only keep rolls     #
] | add;

[   range($H) as $i  | range($W) as $j     # Traverse grid  #
  | get_rolls($i;$j) | select(. < "@@@@@") # <=4 neighbours #
] | length # Count of removable rolls
