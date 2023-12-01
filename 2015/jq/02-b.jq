#!/usr/bin/env jq -n -R -f
[
  inputs / "x" | map(tonumber) |
  sort |
  (.[0]+.[1])*2+(.[0]*.[1]*.[2])
] | add
