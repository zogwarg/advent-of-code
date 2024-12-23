#!/usr/bin/env jq -n -R -f

reduce (
  inputs / "-" #         Build connections dictionary         #
) as [$a,$b] ({}; .[$a] += [$b] | .[$b] += [$a]) | . as $conn |

[ #    Get 3-interconnected groups    #
  ( $conn | keys[] ) as $a |
  $conn[$a][] as $b | select($a < $b) |
  $conn[$a][] as $c | select($b < $c) |
  select(any($conn[$b][]; . == $c ))  |
  #  With at least 1 node starting with 't' #
  [$a,$b,$c] | select(any(.[]; test("^t"))) | debug
] | length
