#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Collect calories per elf
reduce inputs as $line (
  [0];
  if $line == "" then
    . + [0]
  else
    .[-1] += ($line | tonumber)
  end
) |

# Return max calories
max
