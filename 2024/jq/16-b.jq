#!/usr/bin/env jq -n -R -f

([
     inputs/""  | to_entries
 ] | to_entries | map(
     .key as $y | .value[]
   | .key as $x | .value   | { "\([$x,$y])":[[$x,$y],.] }
)|add) as $grid | #           Get indexed grid          #

($grid[]|select(last=="S")|first) as $S | # Our start position #
($grid[]|select(last=="E")|first) as $E | # Our  end  position #

# Queue:   pos,dir  , cost # Seen:        pos,dir   : min_cost    #
{ q: [[  [$S[],1,0] , 0    ]],  s: { "\([$S[],1,0])": 0      }  } |

last(label $out| foreach range(1e9) as $i (.;
  # Until search queue is empty, do min_pop #
  if isempty(.q[]) then break $out end
  | (.q|min_by(last)) as [[$x,$y,$dx,$dy],$d]
  | .q = .q - [[[$x,$y,$dx,$dy],$d]] |

  reduce(
    [[($x+$dx),($y+$dy),$dx,$dy],$d+1], # Take one step  #
    [[$x,$y,(-$dy+0),($dx+0)],$d+1000], # Indirect turn  #
    [[$x,$y,($dy+0),(-$dx+0)],$d+1000]  #   Direct turn  #
  ) as [$n,$nd] (.;
    if
      ($grid["\($n[0:2])"]|last) != "#" and
          $nd < (.s["\($n)"] // 1e9 )
    then
       .s["\($n)"] = $nd |
       .q += [ [$n, $nd ] ]
    end
  ) # Keep costs
))  | . as {$s} |

( [ # Get the minimum cost and direction at the end of maze
    ([$E[],0,1],[$E[],0,-1],[$E[],1,0],[$E[],-1,0]) as $E |
    [ $E, $s["\($E)"] ]
  ] |  min_by(last)
) as [$E, $cost] |

[ [$E,$cost] | recurse(
    . as [[$x,$y,$dx,$dy],$d] |
    [[($x-$dx),($y-$dy),$dx,$dy],$d-1],
    [[$x,$y,(-$dy+0),($dx+0)],$d-1000],
    [[$x,$y,($dy+0),(-$dx+0)],$d-1000] |
    select($s["\(first)"] == last)
    #   Backtrack through maze   #
    #  Staying on optimal paths  #
  ) | first[0:2] # Only keep [x,y]
] | unique | length
