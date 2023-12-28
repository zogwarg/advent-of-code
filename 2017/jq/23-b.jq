#!/usr/bin/env jq -n -R -f

# Get initial value set to b
[ inputs | scan("\\d+") | tonumber ][0] as $b

# "Compiled" version
| .b = $b * 100 + 100000
| .c = .b + 17000
| until (.g == 0;
  if isempty(first(
    # Counting non primes between .b and .c
    range(2; .b|sqrt) as $d | select(.b % $d == 0)
  )) | not then .h += 1 end |
  .g = .b - .c | .b += 17 # In steps of 17
) | .h # Output .h
