#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

def ctob($f): [[0,1]|combinations(4)]["0123456789ABCDEF"|index($f)][];
def btoi:     [pow(2;reverse|indices(1)[])] | add + 0;

[ inputs | ctob(scan(".")) ] | # Get BITS stream

[
  recurse (
      if length < 3  then empty     # Stop if too short for version
    elif .[3:6] != [1,0,0] then     # If not type 4
      if .[6] == 0 then             #   length type 0
        (.[7:7+15]|btoi) as $len |  #     get length
        .[7+15:7+15+$len],          #     split
        .[7+15+$len:]               #
      else                          #   length type 1
        .[7+11:]                    #     continue (ignore len)
      end                           #
    else .[6:]                      # If lit type 4
      | first(                      #
          range(100) as $i          #   Get end of literal
          | select(.[$i*5] == 0)    #
          | $i                      #
        ) as $i                     #
      | .[5*$i+5:]                  #   continue (ignore lit)
    end                             #
  )[0:3] | btoi # Extract versions  #
] | add
