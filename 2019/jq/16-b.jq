#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

[ inputs / "" | .[] | tonumber ] |

(.[0:7]|map(tostring)|add|tonumber) as $offset |
[ limit(10000;repeat(.)) | .[]] | length as $l |

if ($offset|debug({offset: . })) / $l < 0.5 then
  "Offset is lt half of 1000_input" | halt_error
end | .[$offset:] | # We have triangular pattern

reduce range(100) as $_ (. ; debug($_) |
  reduce range((length-1);-1;-1) as $i (
    # Accumulate from last input digit
    . ; .[$i] = (.[$i+1] + .[$i]) % 10
  )
) | map(tostring) | .[0:8] | add
