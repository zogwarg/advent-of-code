#!/usr/bin/env jq -n -f

inputs as $step |

# Do the spinlocking
reduce range(1;2018) as $i (
  [0];
  [$i] + .[$step%length+1:] + .[:$step%length+1]
)

# Output number after 2017
| .[1]
