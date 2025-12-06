#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

#       Get columns of single characters       #
[ inputs / "" ] | transpose | (..|nulls) = " " |

#    Group columns together      #
reduce (.[], [" "]) as $col ([[]];
  # If empty, compute last group #
  if $col | unique == [" "] then
    last = (
      last[0][-1] as $op
      | [ last[][:-1] | add | trim | tonumber ]
      | reduce .[1:][] as $d (.[0];
          if $op == "*" then . * $d
                        else . + $d
                        end
        )
    ) | . + [[]] # Start new group
  else
    #   Add to group    #
    last = last + [$col]
  end
)

| .[:-1] | add