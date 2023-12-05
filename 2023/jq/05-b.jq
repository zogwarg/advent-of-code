#!/usr/bin/env jq -n -R -f

# Utility function
def group_of($n):
  ( length / $n ) as $l |
  . as $arr |
  range($l) | $arr[.*$n:.*$n+$n]
;

# Get all seed ranges
input | [ match("\\d+"; "g").string | tonumber ] | [group_of(2)] as $seeds |

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

# For each map, apply transformation to all seeds ranges.
# Producing new seed ranges if applicable
# seed -> ... -> location
| reduce (to_entries[] | select(.key != "k") .value) as $map ({s:$seeds};
  .s |= [
    # Only attempt transform if seed range and map range instersect
    .[] | [.[0], add, .[1] ] as [$ea, $eb, $el] | [
      $map[] | select(.[1:] | [.[0], add ] as [$sa,$sb] |
        ( $ea >= $sa and $ea < $sb ) or
        ( $eb >= $sa and $eb < $sb ) or
        ( $sa >= $ea and $sa < $eb )
      )
    ] as $range |
    if $range | length > 0 then
      $range[0] as [$d,$s,$l] |
      # ( only end ) inside map range
      if $ea < $s and $eb < $s + $l then
        [$ea, $s - $ea], [$d, $eb - $s ]
      # ( both start, end ) outside map range
      elif $ea < $s then
        [$ea, $s - $ea], [$d, $l], [ $s + $l, $eb ]
      # ( only start ) inside map range
      elif $eb > $s + $l then
        [$ea + $d - $s, $l - $ea + $s ], [$s + $l, $eb - $s - $l]
      # ( both start, end ) inside map range
      else
        [$ea + $d - $s , $el]
      end
    else
      .
    end
  ]
)

# Get lowest location
| [.s[][0]] | min
