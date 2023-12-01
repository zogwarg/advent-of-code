#!/usr/bin/env jq -n -R -f

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
