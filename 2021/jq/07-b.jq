#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  inputs / "," | .[] | tonumber
]

# Save current positions
| . as $pos
# Candidate targets
| [ range(min;max+1) ] as $candidates |
# Caculate total fuel usage for each candidate
[
  foreach $candidates[] as $c ({};
    # Fuel cost          = 1 + + 2 + . + N
    #                    = ( N^2 + N ) / 2
    [$pos[] - $c | abs | . * (. + 1 ) / 2 ] | add
  )
]
# Output smallest
| min
