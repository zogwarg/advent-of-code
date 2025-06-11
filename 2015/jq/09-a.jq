#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  inputs / " "
  | [.[0,2,-1]] | .[-1] |= tonumber # [Place A, Place B, distance]
  | (.), (.[0:2] |= reverse)        # Produce [A,B,dist] and [B,A,dist]
  | {(.[0:2]|join(">")): .[-1]}
] | add as $dist_map |

# Traveling santa problem
([ $dist_map | keys[] / ">" | .[0] ] | unique ) as $places |

# Brute force is O(n!) check if reasonable | fact(n) = gamma(n+1)
if $places | length + 1 | gamma > 5000000 then
  "Number of places is too high for reasonably brute-forcing" | halt_error
else . end |

# Permutations for (unique) input array
def perms:
  if length == 1 then . else
  .[] as $c | ( . - [$c] | perms) as $arr | [$c, $arr[]]
  end
;

# Ouput smallest distance for all perms
[ $places | perms ] | map(
  [.[:-1],.[1:]] | transpose | map($dist_map[join(">")]) | add
) | min
