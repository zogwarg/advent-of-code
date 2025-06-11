#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

def do($step):  #  Using cube coordinates (plane x + y + z = 0)  #
  .[0] += {"w": 0,"e": 0,"nw": 1,"se":-1,"sw":-1,"ne": 1}[$step] |
  .[1] += {"w": 1,"e":-1,"nw": 0,"se": 0,"sw": 1,"ne":-1}[$step] |
  .[2] += {"w":-1,"e": 1,"nw":-1,"se": 1,"sw": 0,"ne": 0}[$step]
;
def toHexTile: reduce scan("se|sw|ne|nw|e|w") as $step (
  [0,0,0]; do($step)
);

#                  Get sparse representation                       #
reduce (inputs|toHexTile) as $xyz ( .; .["\($xyz)"] |= [1,0][.//0] )
|             map_values(select(. == 1)|{s:.})                     |
#     Iteratively get sparse neighbour count, and apply rules      #
reduce range(100) as $i (.;                            debug({$i}) |
  reduce (
    keys[] | fromjson | do("se","sw","ne","nw","e","w") | @json
  ) as $k (.; .[$k].n += 1) | map_values(
      if  .s==1   and .n != 1 and .n != 2 then empty
    elif (.s|not) and .n != 2             then empty end
    # Prepare next step
    | .s = 1 | del(.n)
  )
) | length # How many tiles are black after 100 iterations
