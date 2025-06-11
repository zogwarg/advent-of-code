#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Get LR instructions
( input / "" | map(if . == "L" then 0 else 1 end )) as $LR |
( $LR | length ) as $l |

# Make map {"AAA":["BBB","CCC"], ...}
(
  [
    inputs | select(.!= "") | [ scan("[A-Z]{3}") ] | {(.[0]): .[1:]}
  ] | add
) as $map |

# Start at "AAA", number of steps = 0
["AAA", 0] |

# Update POS and number of steps, until "ZZZ" reached
until (.[0] == "ZZZ"; [ $map[.[0]][ $LR[.[1] % $l] ], .[1] + 1] )

# Output number of steps
.[1]
