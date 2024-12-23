#!/usr/bin/env jq -n -rR -f

reduce (
  inputs / "-" #         Build connections dictionary         #
) as [$a,$b] ({}; .[$a] += [$b] | .[$b] += [$a]) | . as $conn |

[
  #               For pairs of connected nodes                   #
  ( $conn | keys[] ) as $a | $conn[$a][] as $b | select($a < $b) |
  #             Get the list of nodes in common                  #
      [$a,$b] + ($conn[$a] - ($conn[$a]-$conn[$b])) | unique
]

# From largest size find the first where all the nodes in common #
#    are interconnected -> all(connections ⋂ shared == shared)   #
| sort_by(-length)
| first (
  .[] | select( . as $cb |
    [
        $cb[] as $c
      | ( [$c] + $conn[$c] | sort )
      | ( . - ( . - $cb) ) | length
    ] | unique | length == 1
  )
)

| join(",") # Output password
