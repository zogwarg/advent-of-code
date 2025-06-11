#!/bin/sh
# \
exec jq -n -f "$0" "$@"

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

# Group subsets by size
[ subsetsAddingTo(150) | length ] | group_by(.)

# Output how many ways there are of using
# minimum number of containers
| map([ .[0], length])
| min[1]
