#!/bin/sh
# \
exec jq -n -s -R -f "$0" "$@"

# Ignoring "cid"
["byr","iyr","eyr","hgt","hcl","ecl","pid"] as $req_fields |
($req_fields | map(.+":") | join("|")) as $pattern |
reduce (inputs / "\n\n" | .[]) as $pass (0;
  # Counting valid passports
  if $pass | $req_fields - [ match($pattern; "g").string[:-1] ] | length > 0 then . else . += 1 end
)
