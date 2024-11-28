#!/usr/bin/env jq -n -sR -f

inputs / "\n\n" | map([scan("\\d+")|tonumber][1:]) |

# Play the Game
until(any(.[];length == 0);
  .[0][0] as $p1 | .[1][0] as $p2 | map(.[1:]) |
    if $p1 > $p2
  then .[0] += [$p1, $p2]
  else .[1] += [$p2, $p1]
   end
)

# Calculate Winner's score
| .[]                    | select(length>0)
| reverse                | to_entries
| map((.key+1) * .value) | add
