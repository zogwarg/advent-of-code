#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

reduce (
  [ inputs #   Parse every range in order   #
    | trim / "\n\n"  | .[0] / "\n" | .[]    #
    | [ scan("\\d+") | tonumber ]           #
  ] |  sort_by(.[0]) | .[]                  #
) as [$a, $b] ([[-1]]; # Dummy first range  #
  # New range, extend last range, or skip.  #
    if $a > last[-1] then . = . + [[$a,$b]] #
  elif $b > last[-1] then last[-1] = $b end #
) |  [ .[1:][] | 1 + last - first ] | add   #
