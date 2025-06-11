#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

def cmp($b; $cmp; $v2):
    if $cmp == "!=" then
             $b != $v2
  elif $cmp == "<" then
             $b <  $v2
  elif $cmp == "<=" then
             $b <= $v2
  elif $cmp == "==" then
             $b == $v2
  elif $cmp == ">" then
             $b >  $v2
  elif $cmp == ">=" then
             $b >= $v2
  else "Unexpected cmp" | halt_error end
;

reduce(
  inputs / " " | .[2,-1] |= tonumber
) as [$a, $op, $v1, $_, $b, $cmp, $v2] ({"_": 0};
  if cmp(.[$b] // 0; $cmp; $v2) then
    .[$a] = (
      if $op == "inc" then
        ( .[$a] // 0 | . + $v1 )
      else
        ( .[$a] // 0 | . - $v1 )
      end
    ) |
    # Update max value
    .["_"] = ( [.["_"], .[$a]] | max )
  else . end
)

# Output highest reached reg value
| .["_"]
