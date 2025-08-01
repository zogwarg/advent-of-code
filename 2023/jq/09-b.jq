#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  # For each line, get numbers eg: [ [1,2,3] ]
  inputs / " " | map(tonumber) | [ . ] |

  # Until latest row is all zeroes
  until (.[-1] | [ .[] == 0] | all;
   . += [
     # Add next row, where for element(i) = prev(i+1) - prev(i)
     [ .[-1][1:] , .[-1][0:-1] ] | transpose | map(.[0] - .[1])
    ]
  )
  # Get extrapolated previous element for first row
  |  [ .[][0] ] | reverse | reduce .[] as $i (0; $i - . )
]

# Output sum of extapolations for all lines
| add
