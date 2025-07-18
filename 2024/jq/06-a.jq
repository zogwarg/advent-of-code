#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / "" ] | [.,.[0]|length] as [$H,$W]

| {board: with_entries(# Get indexed board #
    .key as $y | .value  |  to_entries[]   |
    .key as $x | {key: "\([$x,$y])", value }
  )}
| .guard = first( #────── Find the guard's starting position ──────#
    .board|to_entries[]|select(.value == "^")|.key|[fromjson,[0,-1]]
  )

| if (.guard|not) then "No guard!" | halt_error end |

until (
  #        Until out-of-bounds             or  loop detected         #
  .guard[0][0] <   0 or .guard[0][1] <   0 or
  .guard[0][0] >= $W or .guard[0][1] >= $H or .s["\(.guard)"];
                                              .s["\(.guard)"] = true |

  if .board["\(.guard|transpose|map(add))"] == "#" then
    .guard[1] |= (.[1] *= -1 | reverse) # Bonk & Turn #
  else
    .guard[0] = (.guard|transpose|map(add)) # Walk on #
  end
)

#   Get total number of blocks on the original path     #
| .s | with_entries(.key |= "\(fromjson|first)") | length
