#!/usr/bin/env jq -n -R -f

#     Board size     # Our list of robots positions and speed #
[101,103] as [$W,$H] | [ inputs | [scan("-?\\d+")|tonumber] ] |

reduce range(100) as $s (.;
  map(.[2:4] as $v | .[0:2] |= (
       [., [$W,$H], $v ]    #                                   #
    | transpose | map(add)  # Add speed to position and ensure  #
    | .[0] %= $W            #   modulo by W and H is positive   #
    | .[1] %= $H            #                                   #
  ))
)

| reduce .[] as [$x,$y] ([];
  if $x < ($W/2|floor) and $y < ($H/2|floor) then
    .[0] += 1
  elif $x < ($W/2|floor) and $y > ($H/2|floor) then
    .[1] += 1
  elif $x > ($W/2|floor) and $y < ($H/2|floor) then
    .[2] += 1
  elif $x > ($W/2|floor) and $y > ($H/2|floor) then
    .[3] += 1
  end
) | .[0] * .[1] * .[2] * .[3] # Product of counts by quandrants #
