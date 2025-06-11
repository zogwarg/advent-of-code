#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  inputs
] | reduce (
  # Can sort over inputs directly, as dates are well-formed
  sort[]
  # Get ints and actions
  | [ match("\\d+"; "g").string | tonumber ] as $ints
  | [ match("falls|wakes"; "g").string | .[0:1] ] as $actions
  | {}
  # Does line include guard id = start shift /or actions
  | .gid = if $ints | length == 6 then $ints[5] else null end
  | .act = if $actions | length == 1 then $actions[0] else null end
  | .tim = $ints[1:5]
) as $entry ({g:{}};
  if $entry.gid then .gid = ( $entry.gid | tostring )
  elif $entry.act == "f" then
   .start = $entry.tim[-1]
  else
   # On wake up, add all asleep minutes
   .g[.gid][range(.start;$entry.tim[-1])] += 1
  end
)

# Strategy 2: Get guard with most slept minutes
| ( [ .g[][] ] | max ) as $max | .g | to_entries[] | select(.value | contains([$max]))

# Return the minute most slept * guard id
| ( .key | tonumber ) as $gid | .value
| index($max) * $gid
