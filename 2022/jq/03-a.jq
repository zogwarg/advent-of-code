#!/usr/bin/env jq -n -R -f
[
  inputs | explode | map(if .>90 then .-96 else .-38 end) | [.[:length/2], .[length/2:]] | .[0] - ( .[0] - .[1] ) | .[0]
] | add
