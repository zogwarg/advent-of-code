#!/usr/bin/env jq -n -R -f

reduce (
  inputs | [scan("[A-Z]"), (scan("\\d+")|tonumber), .] | debug
) as [$m, $n, $s] ({ way: [10,-1], pos:[0,0] };

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
    # Lazy turning reuse unit rotations of first part
    .way as [$a, $b] | (.way|map(abs)) as [$an,$bn] |
    $turn["\([copysign(1;$a),0]+$rot[$s]|debug)"] as $x |
    $turn["\([0,copysign(1;$b)]+$rot[$s]|debug)"] as $y |
    .way = ([($x|map(.*$an)),($y|map(.*$bn))]|transpose|map(add))
  elif $m == "F" then
    .pos = ([.pos, (.way|map(. * $n))] | transpose | map(add))
  elif $m == "E" then .way[0] += $n
  elif $m == "N" then .way[1] -= $n
  elif $m == "W" then .way[0] -= $n
  elif $m == "S" then .way[1] += $n
  else
    [$m,$n] | halt_error
  end | debug({pos,way})
)

# Output final distance
| .pos | map(abs) | add
