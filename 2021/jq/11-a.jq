#!/usr/bin/env jq -n -R -f

#                 Get our map of octopodes                   #
[ inputs / "" | map(tonumber) ] | [.,.[0]|length] as [$H,$W] |

reduce range(100) as $i ({b:.,f:0};
  .b[][] += 1 | until (all(.b[][]; . <= 9);# Any flash ready #
    reduce (
      .b | to_entries[] | .key as $y | .value
         | to_entries[] | .key as $x | .value
         | select(. > 9)
         | [$x,$y]
    ) as [$x,$y] (.; .f += 1| #           Flash              #
      (
        range($y-1;$y+2) as $yy | range($x-1;$x+2) as $xx
        | select($xx >= 0 and $xx < $W )
        | select($yy >= 0 and $yy < $H )
        | select($xx != $x or $yy != $y)
        | .b[$yy][$xx]
      ) |= ( if . != 0 then . + 1  end)
        | .b[$y][$x] = 0 #           Deplete Energy          #
    )
  )
)

| .f #      Our total number of flashes after 100 steps      #
