#!/usr/bin/env jq -n -sR -f
[
#   Split -> Groups | Cleanup last item      |-> People
    inputs / "\n\n" | last |= rtrimstr("\n") | .[] / "\n"
# | $groupSize   | All letters in group
  | length as $l |  (join("") / "" | sort)
# | Group letters| Keep letter groups, if selected by all
  | group_by(.) | [ .[] | select(length == $l) | 1 ]
# | Add up "AND" letters for each group
  | length
] | add
