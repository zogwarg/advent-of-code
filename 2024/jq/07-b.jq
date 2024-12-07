#!/usr/bin/env jq -n -R -f

[ inputs | [ scan("\\d+")|tonumber ] ] |

def possible($l;$acc;$rest):
  if ($rest|length) == 0 then $acc | select(. == $l)
  else
    possible($l; ($acc+$rest[0]|select(. <= $l)); $rest[1:]),
    possible($l; ($acc*$rest[0]|select(. <= $l)); $rest[1:]),
    possible(
      $l;
      [$acc, $rest[0]|tostring]|add|tonumber|select(. <= $l);
      $rest[1:]
    )
  end
;

# Sum the result of all the possible equations. #
map(debug|first(possible(.[0];.[1];.[2:]))) | add
