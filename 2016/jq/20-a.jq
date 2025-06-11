#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce (
  # Parse inputs a low, high ranges
  inputs | [ scan("\\d+") | tonumber ]
) as [$b_low, $b_high ] (
  # Init complete "IP" range
  .ips = [[0, pow(2;32)-1]];

  # For each blocked range,
  # And for each currently allowed range
  # Replace with 1, 2 or 0 allowed ranges
  .ips |= [
    .[] as [$low, $high ] |
    (
      if $low < $b_low then
        [$low, ([$b_low-1, $high] | min)]
      else
        empty
      end
    ),
    (
      if $high > $b_high then
        [([$b_high+1, $low] | max), $high]
      else
        empty
      end
    ) | arrays
  ]
)

# Get lowest allowed ip
| .ips[0][0]
