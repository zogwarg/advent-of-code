#!/usr/bin/env jq -n -R -f

[ inputs
  | [ scan("-?\\d+") | tonumber ] | [ .[0:2], .[2:] ] | transpose
  | [ map(.[0]) , ( map(.[1]-.[0] | abs) | add + 1) ]
] as $sensors | #   Get all sensor zones where beacon can't be  #

first (
  reduce (
    #   Get intersection points of all bounding boxes while  #
    #                  excluding the tips                    #
    $sensors[] as [[$x,$y],$d] |
    [[($x-$d+1),($y-1)],[($x-1),($y-$d+1)],-1],
    [[($x-$d+1),($y+1)],[($x-1),($y+$d-1)], 1],
    [[($x+$d-1),($y-1)],[($x+1),($y-$d+1)], 1],
    [[($x+$d-1),($y+1)],[($x+1),($y+$d-1)],-1]
  ) as [[$ax,$ay],[$bx,$by], $c] ({s:[],p:[]};
    reduce .s[] as [[$Ax,$Ay],[$Bx,$By], $C] (.;
      [[$ax, $bx], [$Ax,$Bx] | sort[] ] as [$x1,$x2,$x3,$x4] |
      [[$ay, $by], [$Ay,$By] | sort[] ] as [$y1,$y2,$y3,$y4] |
      if $c == $C
         or $x4 < $x1 or $x2 < $x3
         or $y4 < $y1 or $y2 < $y3 | not
      then
        .p += [
          [ #  Solved by system of equations  #
            ( $C * $Ax - $c * $ax + $ay - $Ay ),
            ( $c * $C * ($Ax - $ax) + $C * $ay - $c * $Ay) |
            . / ($C - $c)
          ]
          | select(
              . == map(floor) and all(.[]; . > 0 and . < 4e6)
            )
        ]
      end
    )
    | .s += [[[$ax,$ay],[$bx,$by], $c]]
  )
  # Get first point not in range of any sensor #
  | .p[] | select( . as [$x,$y] | all(
      $sensors[]; . as [[$X,$Y],$d] |
      [ ($X - $x), ($Y- $y) | abs ] | add >= $d
    ))
)

# Output tuning freq
| first * 4e6 + last
