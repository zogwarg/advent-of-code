#!/usr/bin/env jq -n -R -f

# Array of all letters
[ inputs / "" | .[] ]
# Transform to array Sliding window [ [0,1,2,3], [1,2,3,4], ... ]
| [ . , .[1:], .[2:], .[3:] ] | transpose
# Map to number of unique chars, test == 4, at each position (offset 4)
| map(unique | add | length == 4)
# Output index of start position
| 4 + index(true)
