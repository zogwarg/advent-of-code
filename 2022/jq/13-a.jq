#!/bin/sh
# \
exec jq -n -f "$0" "$@"

[ inputs ] | . as $in | [range(0;length;2) | $in[.:.+2] ] |

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

[ .[] | compare(.[0];.[1]) ] | indices(true) | map(.+1) | add
