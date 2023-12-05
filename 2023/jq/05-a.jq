#!/usr/bin/env jq -n -R -f

# Get seeds
input | [ match("\\d+"; "g").string | tonumber ] as $seeds |

# Collect maps
reduce inputs as $line ({};
  if $line == "" then
    .
  elif $line | test(":") then
    .k = ( $line / " " | .[0] )
  else
    .[.k] += [[ $line | match("\\d+"; "g").string | tonumber ]]
  end
)

# For each map, apply transformation to all seeds.
# seed -> ... -> location
| reduce ( to_entries[] | select(.key != "k") .value) as $map ({s:$seeds};
  .s[] |= (
    # Only attempt transform if element is in one of the ranges
    [ . as $e | $map[] | select(. as  [$d,$s,$l] | $e >= $s and $e < $s + $l) ] as $range |
    if ($range | length ) > 0 then
      $range[0] as [$d,$s] |
      . - $s + $d
    else
      .
    end
  )
)

# Get lowest location
| .s | min
