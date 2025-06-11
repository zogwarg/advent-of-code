#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Produce 3-wide sliding window
[ inputs | tonumber ] |
[ .[:-2], .[1:-1], .[2:] ] | transpose | map(add) |

# Re-use part 1 code
{prev: .[0], sum: 0} as $init |
reduce .[1:][] as $i ($init;
  if $i > .prev then
    .sum += 1 |
    .prev = $i
  else
   .prev = $i
  end
) |

# Output sum
.sum
