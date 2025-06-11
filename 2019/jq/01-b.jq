#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# recursive required fuel
def req_fuel:
  . / 3 | floor - 2 |
  if . < 0 then
    empty
  elif . < 3 then
    .
  else
    ., req_fuel
  end
;

[ inputs | tonumber | req_fuel ] | add
