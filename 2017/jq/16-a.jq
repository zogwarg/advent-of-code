#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

reduce (
  # Parse inputs
  inputs / "," | .[] | [
    .[0:1],
    (.[1:] / "/" | .[] | (if tonumber? // false then tonumber end))
  ]
) as [$m, $a, $b] ("abcdefghijklmnop" / "";
  # Shift Right
  if $m == "s" then
    .[16-$a:] + .[:16-$a]
  # Swap positions
  elif $m == "x" then
    .[$a] as $x | .[$a] = .[$b] | .[$b] = $x
  # Swap letters
  elif $m == "p" then
     [index($a,$b)] as [$a,$b]  |
    .[$a] as $x | .[$a] = .[$b] | .[$b] = $x
  end
  # Output final string
) | add
