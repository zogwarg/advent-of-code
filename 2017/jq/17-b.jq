#!/usr/bin/env jq -n -f

inputs as $step |

# Do the spinlocking
last(
  foreach range(1;5e7+1) as $i (
    0;                          # Keeping "0" in position 0
    ( . + $step ) % $i + 1;     # Position of current insert
    select(. == 1) | $i | debug # If curr = 1, then it is after zero
  )
)

# After 50 million inserts
# Number after zero
| .
