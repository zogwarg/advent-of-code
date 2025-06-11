#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / "-" | ., reverse ] | group_by(.[0])
| map({(.[0][0]): map(.[1]) })
| { edges: add, pos: "start", twice: false, p: ["start"]}
| .edges[] -= ["start"]
| [
    recurse( # Until we reach the end
      if .pos == "end" then empty end
      | .next = .edges[.pos][]?
      | if   (.pos| . == ascii_downcase) and .twice then
          del(.edges[.pos])
        elif (.pos| . == ascii_downcase) then
          # Fork into 2 visits, and 1 visit
          (.twice = true), del(.edges[.pos])
        end
      | .pos = .next # Update to next
      | .p += [.pos] # Build path
    ) | select(.pos == "end") | .p
  ]   # Keep paths that reach the end
| unique | length
