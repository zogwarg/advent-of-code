#!/usr/bin/env jq -n -f

# Sort inputs for counting
[ inputs ] | sort_by(-.) |

# Gets all the subsets adding up to n
def subsetsAddingTo($n): .[0] as $a |
  if $n == 0 then
     []
  elif (add < $n) then
     empty
  elif (add == $n) then
     .
  elif $a <= $n then
    (.[0:1] + ( .[1:] | subsetsAddingTo($n-$a) )),
    ( .[1:] | subsetsAddingTo($n) )
  else
    ( .[1:] | subsetsAddingTo($n) )
  end
;

# Count number of combinations
# That can hold 150L of eggnog
[subsetsAddingTo(150)] |length
