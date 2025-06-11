#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs | [ scan("\\d+") | tonumber] ] as $layers |

def severity($layer; $time):
  $layer as [$depth, $range] |
  if $time % ( 2 * $range - 2 ) != 0 then 0 else
    # Depth + 1, so 0 also has severity
    ($depth + 1) * $range
  end
;

first(
  range(infinite) as $wait |
  [ # Each layer is reached at time == depth + wait
    first(
      # Stop at first layer with sev > 0 for wait
      $layers[] | severity(.; .[0] + $wait) |
      select(. != 0)
    )
    # Get first wait with total severity == 0
  ] | select(add == null) | $wait
)
