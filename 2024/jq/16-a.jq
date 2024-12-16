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
  )
))

#    Get lowest cost at END for each possible orientation    #
| [ .s["\([$E[],0,1],[$E[],0,-1],[$E[],1,0],[$E[],-1,0])"] ] | min
