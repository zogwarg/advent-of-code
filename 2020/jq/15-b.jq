#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs | scan("\\d+") | tonumber ] as $in |

reduce range(30000000) as $i (
  {
    seen, last, next
  };
  if ($i < ($in|length)) then
    .next = $in[$i]
  elif .seen[.last]|not then .next = 0
                        else .next = $i - .seen[.last]
                        end|
  if $i != 0 then .seen[.last] = $i end |
  .last = .next | if $i % 10000 == 0 then debug({$i}) end

) | .last # Slow but works
