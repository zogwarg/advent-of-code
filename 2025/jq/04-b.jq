#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[  inputs /   ""   ]             | #    Grid    #
[ .[0], . | length ] as [$W, $H] | # Dimensions #

def get_rolls($i; $j): [
    ($i+(-1,0,1)) as $i # 3x3 #
  | ($j+(-1,0,1)) as $j # box # Don't go outside the grid #
  | select( $i >= 0 and $i < $H and $j >= 0 and $j < $W ) #
  | .grid[$i][$j] | select(. == "@") #  Only keep rolls   #
] | add;

# Current     # Update  # Removable # Stop marker #
{ grid: null, new: .,   count: 0,   stop: false } |

until (.stop;
  # Copy state # Reset marker #
  .grid = .new | .stop = true | reduce (
    range($H) as $i | range($W) as $j #
    |  {$i, $j} #    Traverse Grid    #
  ) as {$i, $j} (.;
    #   We only need to update removals after complete copy    #
    if .grid[$i][$j] == "@" and get_rolls($i;$j) < "@@@@@" then
      .new[$i][$j] = "." | .count = .count + 1 | .stop = false
    end
  )
) | .count # Final count of removable rolls
