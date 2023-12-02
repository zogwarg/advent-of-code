#!/usr/bin/env jq -n -R -f

# Create empty fabric
{
  "fabric": [ range(1000) | [ range(1000) | 0] ]
} as $init |

reduce (
  # Parse each line to numbers
  inputs | split("[#,x]| @ |: ";"")[1:] | map(tonumber)
) as $line (
  $init;
  # Update fabric
  .fabric
    [$line[1] + range($line[3])]
    [$line[2] + range($line[4])] += 1
)

# Sum all pathches of fabric covered more than once
| [ .fabric | .. | numbers | select(. > 1) | 1 ] | add
