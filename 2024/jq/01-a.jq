#!/usr/bin/env jq -n -R -f

# Get the two lists in sorted order
[ inputs | [scan("\\d+")|tonumber]]
| transpose | map(sort)

# Output the total list distance
| transpose | map(.[0]-.[1]| abs)
| add
