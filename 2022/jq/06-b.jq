#!/usr/bin/env jq -n -R -f

# Array of all letters
[ inputs / "" | .[] ]
# Transform to array Sliding window [ [0,1,2,3], [1,2,3,4], ... ]
| [ .[range(14):] ] | transpose
# Map to number of unique chars, test == 14, at each position (offset 14)
| map(unique | add | length == 14)
# Output index of start position
| 14 + index(true)
