#!/bin/sh
# \
exec jq -n -f "$0" "$@"

[ inputs, [[2]], [[6]] ] |

def compare($a;$b):
    if ($a|length) == 0 and ($b|length) >  0 then true
  elif ($a|length) >  0 and ($b|length) == 0 then false
  elif ($a|length) == 0 and ($b|length) == 0 then null
  elif ($a[0]|type=="number") and ($b[0]|type=="number") then
      if $a[0] < $b[0] then true
    elif $a[0] > $b[0] then false
    else compare($a[1:];$b[1:]) end
  elif ($a[0]|type=="array") and ($b[0]|type=="array") then
    compare($a[0];$b[0]) as $c |
    if $c == null then compare($a[1:];$b[1:]) else $c end
  else
    compare(
      $a|first|=(if type == "number" then [.] end);
      $b|first|=(if type == "number" then [.] end)
    )
  end
;

def insertSort:
  def _insert: .[1] as [$a] |
    ( # Get index of first element that must come after "a" #
      [ .[0][] | select(                                    #
          compare($a; .)                                    #
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

insertSort | (index([[[2]]])+1) * (index([[[6]]])+1)
