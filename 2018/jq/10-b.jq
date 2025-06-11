#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

# Get list of points as <x,y,dx,dy>
[ inputs | [ scan("-?\\d+") | tonumber ]] |


# Check all the steps that minimize the distance, close to "zero"
([ # "Cheat" by only checking 3 points
  .[0:3][] | [
    [range(.[0];.[2]*10;.[2])], # Generate list of x positions for each step
    [range(.[1];.[3]*10;.[3])]  # Generate list of y positions for each step
  ]
  | transpose  | map(select(.[0] and .[1]))      #Zip X and Y as (x,y) pairs
  | to_entries | min_by(.value|map(abs)|add).key # Get step idx, of min dist
  # Output smaller range of steps within which the the total distance is min
] | [min,max]) as [ $steps_min, $steps_max] |

([
  range($steps_min;$steps_max) as $steps | # For "steps"  in candidate range
  map(
    . as [$x,$y,$i,$j]|[[$x,$y],[$i,$j]] | # Translate all points by n steps
    transpose | map(.[0] + $steps *.[1])
  )
  | [max, $steps] # For each candidate number of steps, get point with x_max
] | min) as [$_, $steps] | # We chose the number of steps where x_max is min

# Output the number of steps where text appears
$steps
