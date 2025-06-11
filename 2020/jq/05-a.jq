#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  inputs / ""
  | [ .[0:7], .[7:] ] as [$r, $c]
  | reduce $r[] as $l ([range(128)]; if $l == "F" then .[:length/2] else .[length/2:] end) | . as [$r]
  | reduce $c[] as $l ([range(8)];   if $l == "L" then .[:length/2] else .[length/2:] end) | . as [$c]
  | $r * 8 + $c
] | max
