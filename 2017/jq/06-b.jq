#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Setup state
{banks: [inputs | scan("\\d+") | tonumber]} | ( .banks | length ) as $l | . + {s: [], i: 0}

# Loop until bank configuration has already been seen
| until ((.banks  | join("|")) as $b | .s | contains([$b]);
  .i += 1 | .s += [.banks | join("|")] |
  .banks |= (
    max as $m | index($m) as $i |
    .[$i] = 0 |
    # Redistribute
    .[($i + 1 + range($m)) % $l] += 1
  )
)

# Output size of loop: steps - index(state)
| .i - ((.banks  | join("|")) as $b | .s | index($b))
