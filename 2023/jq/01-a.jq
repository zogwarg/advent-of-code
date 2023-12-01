#!/usr/bin/env jq -n -R -f

# Get and reduce every "pretty" line
reduce inputs as $line (
  0;
  # Add extracted number
  . + ( $line / "" | [ .[] | tonumber? ] | [first * 10 , last] | add )
)
