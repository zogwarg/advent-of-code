#!/usr/bin/env jq -n -sR -f

inputs | rtrimstr("\n") / "\n\n" |

(.[0] | (. / "\n" | map([scan("\\d+")|tonumber]))) as $rules  |
(.[1] | (. / "\n" | map([scan("\\d+")|tonumber]))) as $prints |

[
  $prints[] | debug(.)
  | select(
  # Check order of every print pair #
      all(
          range(length-1)    as $i
        | range($i+1;length) as $j
        | $rules[] as $r
        | [ .[$i], .[$j] ]
        | select(. | inside($r))
        | [ ., $r ]
        ;
              first == last
      )
    )
  | .[length/2] #  Extract middle  #
] | add
