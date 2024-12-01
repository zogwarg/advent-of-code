#!/usr/bin/env jq -n -R -f

# Get the two lists, in read order
[ inputs | [scan("\\d+")|tonumber]]
| transpose |

reduce .[0][] as $i (
  {
    l: (       # Build lookup table, of ID to number #
      reduce ( #    of occurences in second list     #
        .[1] | group_by(.) | .[] | [.[0],length]
      ) as [$j,$l] ([]; .[$j] = $l)
    ),
    s: 0
  };
  .s = .s + (.l[$i] // 0) * $i #  Gather similarity  #
)

| .s # Final similarity score
