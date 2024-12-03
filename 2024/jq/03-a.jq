#!/usr/bin/env jq -n -R -f

[
  inputs | scan("mul\\(\\d+,\\d+\\)")
         | [ scan("\\d+") | tonumber ]
         | .[0] * .[1]
]        | add
