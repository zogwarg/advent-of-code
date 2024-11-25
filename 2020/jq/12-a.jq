#!/usr/bin/env jq -n -R -f

reduce (
  inputs | [scan("[A-Z]"), (scan("\\d+")|tonumber), .] | debug
) as [$m, $n, $s] ({ dir: [1,0], pos:[0,0] };

  {
    "L180": ["M"], "R180": ["M"],
     "L90": ["L"], "R270": ["L"],
     "R90": ["R"], "L270": ["R"]
  } as $rot |

  {
    "\([-1,0,"R"])":[0,-1],"\([-1,0,"L"])":[0, 1],
    "\([-1,0,"M"])":[1, 0],"\([ 1,0,"R"])":[0, 1],
    "\([ 1,0,"L"])":[0,-1],"\([ 1,0,"M"])":[-1,0],
    "\([ 0,1,"R"])":[-1,0],"\([ 0,1,"L"])":[1, 0],
    "\([ 0,1,"M"])":[0,-1],"\([0,-1,"R"])":[1, 0],
    "\([0,-1,"L"])":[-1,0],"\([0,-1,"M"])":[0, 1]
  } as $turn |

  if $rot[$s] then
    .dir = $turn["\(.dir + $rot[$s])"]
  elif $m == "F" then
    .pos = ([.pos, (.dir|map(. * $n))] | transpose | map(add))
  elif $m == "E" then .pos[0] += $n
  elif $m == "N" then .pos[1] -= $n
  elif $m == "W" then .pos[0] -= $n
  elif $m == "S" then .pos[1] += $n
  else
    [$m,$n] | halt_error
  end | debug({pos})
)

# Output final distance
| .pos | map(abs) | add
