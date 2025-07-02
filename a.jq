#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

24 as $min |

[ inputs
  | [ scan("\\d+") | tonumber ]
  | . as [$id,$oro,$cro,$sro,$src,$gro,$grs]
  | debug({$id,$oro,$cro,$sro,$src,$gro,$grs})
  | [
      { min: 0, bots: [1,0,0,0], ore: [0,0,0,0] } 
      | recurse(
        if .min > $min - 1 then empty else
          .min = .min + 1 | .bots as $b | .ore as $o |
          .ore = ([ $o, $b ] | transpose| map(add))  |
          .taint = false |
          if
                $o[0] >= $oro and $o[0] < $oro + $b[0]
            and (.taint|not)
          then
            ., (
                .ore[0] = .ore[0] - $oro
              | .bots[0] = .bots[0] + 1
              | .taint = true
            )            
          end |
          if
                $o[0] >= $cro and $o[0] < $cro + $b[0]
            and (.taint|not)
          then
            ., (
                .ore[0] = .ore[0] - $cro
              | .bots[1] = .bots[1] + 1
              | .taint = true
            )
          end |
          if
                  $o[0] >= $sro        and $o[1] >= $src
            and ( $o[0] <  $sro + $b[0] or $o[1] <  $src + $b[1] )
            and (.taint|not)
          then
            ., (
                .ore[0] = .ore[0] - $sro | .ore[1] = .ore[1] - $src
              | .bots[2] = .bots[2] + 1
              | .taint = true
            )
          end |
          if
                  $o[0] >= $gro        and $o[2] >= $grs
            and ( $o[0] <  $gro + $b[0] or $o[2] <  $grs + $b[2] )
            and (.taint|not)
          then
            ., (
                .ore[0] = .ore[0] - $gro | .ore[2] = .ore[2] - $grs
              | .bots[3] = .bots[3] + 1
              | .taint = true
            )
          end
        end
      ) | select(.min == $min) 
    ] | max_by(.ore[3],(.bots|reverse))
  | debug | $id * .ore[3]
] | add
