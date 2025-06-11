#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs | [ scan("\\d+") | tonumber] ] as $layers |

def severity($layer; $time):
  $layer as [$depth, $range] |
  if $time % ( 2 * $range - 2 ) != 0 then 0 else
    $depth * $range
  end
;

[ # Each layer is reached at time == depth
  $layers[] | severity(.; .[0])
  # Output total severity
] | add
