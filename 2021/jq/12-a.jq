#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / "-" | ., reverse ] | group_by(.[0])
| map({(.[0][0]): map(.[1]) })
| { edges: add, pos: "start" }
| [
    recurse( # Until we reach the end
      if .pos == "end" then empty end
      | .next = .edges[.pos][]?
      # Last time we leave node, if it is lowercase
      | del(.edges[.pos|select(. == ascii_downcase)])
      | .pos = .next # Update to next
    ) | select(.pos == "end")
  ]   # Keep paths that reach the end
| length
