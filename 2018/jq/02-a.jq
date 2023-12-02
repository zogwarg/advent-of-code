#!/usr/bin/env jq -n -R -f

reduce inputs as $line ([0,0];
  # Tally counts of 2s and 3s
  ( [ $line / "" | group_by(.) | map(length) | unique[] | {(tostring):1}] | add) as $counts |
  .[0] += $counts["2"] |
  .[1] += $counts["3"]
) |

# Output product of tallies
.[0] * .[1]
