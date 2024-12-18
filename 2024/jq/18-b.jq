#!/usr/bin/env jq -n -rR -f

([{"\(range(71) as $x | range(71) as $y | [$x,$y])": 0 }
]|add)  | #         Intialize grid with zeroes         #
. as $Z | #             And save for re-use            #

[ inputs | [ scan("\\d+") | tonumber ] ] as $inputs |

# BFS Search for distance to the end for given number of falls #
def BFS($falls): reduce limit($falls; $inputs[]) as [$x,$y] ($Z;
              .["\([$x,$y])"] = 1
  )         | . as $grid         |
  #───────────────────────────────────────────#
  { q: [[[0,0], 0]], s: {"[0,0]": 0}} | until (
    .s["[70,70]"]   or  isempty(.q[])   ;
    .q[0] as [[$x,$y],$d] | .q = .q[1:] |
    reduce (
      ([($x+1),$y],[($x-1),$y],[$x,($y+1)],[$x,($y-1)]) |
      [ . , ($d+1) ] | select( $grid["\(first)"] == 0 )
    ) as [$n,$nd] (.;
      if .s["\($n)"]|not then
        .s["\($n)"] = $nd |
        .q += [ [$n, $nd] ]
      end
    )
  ) | .s["[70,70]"]; # Returns null or distance

#  Do binary search for first blockage   #
[1024, ($inputs|length)] as [$low,$high] |
last(limit(($high-$low)|logb+1;
  [$low, $high] | recurse(. as [$low,$high] |
    (($low + $high) / 2 | trunc) as $mid |
    if BFS($mid) == null then [$low,$mid ]
                         else [$mid,$high] end
  )
)) | nth(last-1;$inputs[]|join(","))
