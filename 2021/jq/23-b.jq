#!/usr/bin/env jq -n -R -f

{ A:0, B:1, C:2, D:3 } as $idx   | # Our amphipod types        #
[   1,  10, 100,1000 ] as $costs | # Their cost                #
[   2,   4,   6,   8 ] as $dest  | # Their final destination   #

( [ inputs / "" ] | transpose[1:-1] # Our Board state as array #
  |[.[]|[add|$idx[scan("[A-D]")]]]  # [[], [], [1,2], [], ...] #
  |.[2]|= (.[0:1] + [3,3] + .[1:])  #                          #
  |.[4]|= (.[0:1] + [2,1] + .[1:])  #     With added rows      #
  |.[6]|= (.[0:1] + [1,0] + .[1:])  #                          #
  |.[8]|= (.[0:1] + [0,2] + .[1:])  #                          #
) as $board |

( $board | [ to_entries[]                 #                       #
  | (.key as $k|$dest|index($k)) as $i    #  Desired Board State  #
  | .value | if $i then [$i,$i,$i,$i] end #                       #
]) as $final |                            #                       #

$board # TODO: Better pruning or Different approach
