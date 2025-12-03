#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ def left_most: (.value|tonumber), -.key;
  #  String with indices  #
  inputs  / "" | to_entries
  #      Left-most max digit which isn't the last one        #
  | ( .[0:-1 ] | max_by(left_most) ) as { key: $i, value: $l }
  #                Maximum Remaining digit                   #
  | ( .[$i+1:] | max_by(left_most) ) as {          value: $r }
  |   $l + $r  | tonumber
] | add