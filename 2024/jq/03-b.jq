#!/usr/bin/env jq -n -R -f

reduce (
  inputs |   scan("do\\(\\)|don't\\(\\)|mul\\(\\d+,\\d+\\)")
         | [[scan("(do(n't)?)")[0]], [ scan("\\d+") | tonumber]]
) as [[$do], [$a,$b]] (
  { do: true, s: 0 };
    if $do == "do" then .do = true
  elif $do         then .do = false
  elif .do         then .s = .s + $a * $b end
) | .s
