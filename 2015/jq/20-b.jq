#!/bin/sh
# \
exec jq -n -f "$0" "$@"

inputs as $gifts |

# /30 is a bit agressive
# /10 is guaranteed to find, but slower
( $gifts / 30 ) as $max_elf |

first(
  reduce range(1; $max_elf) as $elf ([range($max_elf)|0];
    reduce range($elf; ([50 * ($elf+1),$max_elf]|min); $elf) as $house (.;
      .[$house] += 11 * $elf
    )
  )
  | to_entries[] | select(.value >= $gifts)
)

# Output first house with more than $gifts
| .key
