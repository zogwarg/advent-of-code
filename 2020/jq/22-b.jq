#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

inputs / "\n\n" | map([scan("\\d+")|tonumber][1:]) |

def play($b):
  {
    s:{}, $b, w: null
  }|
  until (.w;
    if .s["\(.b)"] then
      .w = 0
    else
      .s["\(.b)"] = true |
      .b[0][0] as $p1 | .b[1][0] as $p2 | .b[] |= .[1:] |
      if (.b[0]|length) < $p1 or (.b[1]|length) < $p2 then
          if $p1 > $p2
        then .b[0] += [$p1, $p2]
        else .b[1] += [$p2, $p1]
         end
      else
        play(.b | [.[0][:$p1],.[1][:$p2]]) as {$w} |
          if $w == 0
        then .b[0] += [$p1, $p2]
        else .b[1] += [$p2, $p1]
         end
      end
    end
    | if (.b[1]|length) == 0 then .w = 0 end
    | if (.b[0]|length) == 0 then .w = 1 end
  )
;

  play(.).b[]      # Recursive play
| select(length>0) | reverse
| to_entries       | map((.key+1) * .value)
| add              # And final score
