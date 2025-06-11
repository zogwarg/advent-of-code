#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  inputs / "," | .[] | tonumber
]

# Save current positions
| . as $pos
# Candidate targets
| [ range(min;max+1) ] as $candidates
# Caculate total fuel usage for each candidate
| [ foreach $candidates[] as $c ({}; [$pos[] - $c | abs] | add) ]
# Output smallest
| min
