#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

inputs | rtrimstr("\n") / "\n\n" |

(.[0] | (. / "\n" | map([scan("\\d+")|tonumber]))) as $rules  |
(.[1] | (. / "\n" | map([scan("\\d+")|tonumber]))) as $prints |

def insertSort:
  def _insert: .[1] as [$a] |
    ( # Get index of first element that must come after "a" #
      [ .[0][] | select(                                    #
          $rules[] as [$x,$y] | . == $y and $a == $x        #
        ) // false | if . then true end                     #
      ] | index(true) // length                             #
    ) as $i | #─────────────────────────────────────────────#
    .[0][0:$i] + [$a] + .[0][$i:] #        Insert           #
  ;
  def _insertSort:
    if (.[1]|length) > 1 then
      [([.[0],.[1][0:1]]|_insertSort),.[1][1:]] | _insertSort
    else _insert end
  ;

  [.[0:1],.[1:]] | _insertSort #   Rescursively sort list   #
;

[
  $prints[] | debug(.)
  | [ ., insertSort ]
  | select(first != last) # Only keep fixed lists #
  | last | .[length/2]    #  Extract new middle   #
] | add
