#!/usr/bin/env jq -n -R -f

([{"\(range(71) as $x | range(71) as $y | [$x,$y])": 0 }
]|add) | #         Intialize grid with zeroes          #

#──────────────── Only make first 1024 blocks fall ──────────────────#
reduce limit(1024; inputs | [scan("\\d+") | tonumber]) as [$x,$y] (.;
                      .["\([$x,$y])"] = 1
)                   | . as $grid          |

#──── BFS Search for distance to the end ───#
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
) | .s["[70,70]"]
