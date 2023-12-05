#!/usr/bin/env jq -n -R -f
reduce (
  inputs
  | [ match("(on|off|toggle) (\\d+),(\\d+) through (\\d+),(\\d+)").captures[].string ]
  | .[1:] |= map(tonumber)
) as [$act, $xa, $ya, $xb, $yb] ([range(1000) | [range(1000) | 0]];
  .[range($xa; $xb + 1)][range($ya; $yb + 1)] |= (
    if $act == "on" then . + 1 elif $act == "off" and . > 0 then . - 1 elif $act == "off" then 0 else . + 2 end
  )
) | [ .[][] ] | add
