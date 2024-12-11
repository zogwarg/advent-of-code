#!/usr/bin/env jq -n -f

last(limit(1+25;
  [inputs] | recurse(map(
    if . == 0 then 1 elif (tostring | length%2 == 1) then .*2024 else
      tostring | .[:length/2], .[length/2:] | tonumber
    end
  ))
)|length)
