#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Get and reduce every "pretty" line
reduce inputs as $line (
  0;
  # Add extracted number
  . + ( $line / "" | [ .[] | tonumber? ] | [first * 10 , last] | add )
)
