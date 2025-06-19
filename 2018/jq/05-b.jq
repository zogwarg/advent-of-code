#!/bin/sh
# \
F="$0" I="$1" exec sh -c 'seq 0 9 | xargs -P 10 -n1 -I {} jq -n --unbuffered -cR -f "$F" --argjson s {} --argjson p 10 "$I" | jq -f "$F" --argjson agg 1'

$ARGS.named as {$s,$p,$agg} | [ ($s // 0), ($p // 1) ] as [$s, $p] |

if ($agg|not) then

# Prepare pattern to replace with ""
("aA" | explode) as [$a,$A] |
([range($a; $a + 26)] | implode / "") as $low |
([range($A; $A + 26)] | implode / "") as $up |
([ [$low, $up ] | transpose[] | .[0] + .[1] , .[1] + .[0] ] | join("|")) as $pair |

[
  # Use each modified string as input
  inputs | gsub(
    range(0; 26) | select( . % $p == $s )
    | [ . + $a, . + $A ] | "[\(implode)]";""
  ) |
  # Operate on string, until it no longer changes
  {
    i: .,
    t: ""
  } | until (.i == .t ; .t = .i | .i |= gsub($pair; ""))

  # Get min for parallel slice
  | .i | length
] | min

else

# Output overall minimum
[ inputs ] | min

end