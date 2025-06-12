#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce (
  inputs | [ scan("on|off|toggle"), ( scan("\\d+") | tonumber ) ]
) as [$act, $xa, $ya, $xb, $yb] (
  [ range(1000) | [ range(1000) | 0 ] ];
  if   $act == "on" then
    .[$xa:$xb+1][][$ya:$yb+1] |= map(. + 1)
  elif $act == "off" then
    .[$xa:$xb+1][][$ya:$yb+1] |= map(. - 1 | [0,.] | max)
  elif $act == "toggle" then
    .[$xa:$xb+1][][$ya:$yb+1] |= map(. + 2)
  else
    "Unexpected action: \({$act})" | halt_error
  end

) | [ .[] | add ] | add
