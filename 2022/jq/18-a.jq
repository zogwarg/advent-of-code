#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce (
  inputs | [ scan("\\d+") | tonumber ]
         | range(3) as $i | .[$i] = .[$i] + ( .5, - .5)
) as $xyz ({}; .["\($xyz)"] += 1 )

| with_entries(select(.value == 1)) | length
