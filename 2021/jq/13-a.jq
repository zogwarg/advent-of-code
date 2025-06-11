#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

inputs / "\n\n"

| .[0] |= ( . / "\n" |  map([scan("\\d+")|tonumber]) )
| .[1] |= [ scan("[xy]=\\d+")/"=" | .[1] |= tonumber ]

| reduce .[1][0:1][] as [$f,$v] (.[0];
    def fold($i): map(if .[$i] > $v then .[$i] = 2 * $v - .[$i] end);
                      if  $f == "y" then fold(1)
                     elif $f == "x" then fold(0) end
  )
| unique | length
