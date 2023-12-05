#!/usr/bin/env jq -n -R -f

# Prepare pattern to replace with ""
("aA" | explode) as [$a,$A] |
([range($a; $a + 26)] | implode / "") as $low |
([range($A; $A + 26)] | implode / "") as $up |
([ [$low, $up ] | transpose[] | .[0] + .[1] , .[1] + .[0] ] | join("|")) as $pair |

# Operate on string, until it no longer changes
{
  i: inputs,
  t: ""
} | until (.i == .t ; .t = .i | .i |= gsub($pair; ""))

# Output polymer length
| .i | length
