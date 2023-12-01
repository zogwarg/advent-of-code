#!/usr/bin/env jq -n -R -f
{prev: (input | tonumber), sum: 0} as $init |
reduce (inputs | tonumber) as $i ($init;
  if $i > .prev then
    .sum += 1 |
    .prev = $i
  else
   .prev = $i
  end
) |

# Output sum
.sum
