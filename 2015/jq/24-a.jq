#!/bin/sh
# \
exec jq -n -f "$0" "$@"

[ inputs ] as $inputs |

# Generate unique combinations of size $n
# From array $arr
def combinations($arr;$n):
  if $arr == [] then
    []
  elif $n == 1 then
    $arr[] as $x | [$x]
  else
    range(($arr|length)-$n+1) as $i |
    [$arr[$i]] + combinations($arr[$i+1:];$n-1)
  end
;

($inputs | add / 3) as $sum |
($inputs | length ) as $n   |

first(
  # Testing in turn for size of first group 1,2,3,...
  foreach range(1;$n) as $i (
    infinite;
    reduce (
      # For all combinations of size $i sums to $sum
      combinations($inputs; $i) | select(add == $sum)
    ) as $combination (infinite;
      # Get the minimum QE
      [ ., reduce ($combination[]) as $j (1; . * $j )] | min
    ) | if . == infinite then empty end
  )
)
