#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce range(80) as $i ([inputs | scan("\\d+") | tonumber];
  # Produce two lanternfish when 0
  . |= [ .[] | if . > 0 then . - 1 else 6, 8 end ]
) | length # Count fish
