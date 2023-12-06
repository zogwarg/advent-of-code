#!/usr/bin/env jq -n -R -f
reduce range(80) as $i ([inputs | scan("\\d+") | tonumber];
  # Produce two lanternfish when 0
  . |= [ .[] | if . > 0 then . - 1 else 6, 8 end ]
) | length # Count fish
