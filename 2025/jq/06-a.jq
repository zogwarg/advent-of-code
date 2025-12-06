#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs | [ scan("\\d+|[*+]") | tonumber? // . ] ]

| [
    transpose[]
  | if   last == "*"
    then reduce .[1:-1][] as $d (.[0]; . * $d)
    else .[0:-1] | add
    end
  ]
| add
