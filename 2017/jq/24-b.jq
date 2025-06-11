#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Get available bridge parts
[ inputs / "/" | map(tonumber) | sort ] as $available |

{ # Build bridge recursively from compatible parts
  bridge: [[0,0]],
  $available
} |
[
  recurse(
    . as {$bridge,$available} | .bridge[-1][1] as $r |

      # Find parts that connect to rightmost end
      # Transfer them from available to bridge
      $available[]
    | select(.[0] == $r or .[1] == $r ) | . as $next
    | ( $available - [$next] ) as $available
    | if .[0] != $r then reverse end
    | { bridge: ($bridge + [.]), $available }
  )
  # Get the bridge length and strength
  | .bridge | [ length, (add|add) ]
  # Output strength of longest bridge
] | max[1]
