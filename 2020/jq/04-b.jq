#!/bin/sh
# \
exec jq -n -s -R -f "$0" "$@"

# Ignoring "cid"
["byr","iyr","eyr","hgt","hcl","ecl","pid"] as $req_fields |
# Abusive use of regex for validation ^^
(
  "byr:19[2-9][0-9]\\b|byr:200[0-2]\\b|"
+ "iyr:201[0-9]\\b|iyr:2020\\b|"
+ "eyr:202[0-9]\\b|eyr:2030\\b|"
+ "hgt:1[5-8][0-9]cm\\b|hgt:19[0-3]cm\\b|"
+ "hgt:59in\\b|hgt:6[0-9]in\\b|hgt:7[0-6]in\\b|"
+ "hcl:#[0-9a-f]{6}\\b|"
+ (["amb","blu","brn","gry","grn","hzl","oth"] | map("ecl:" + . + "\\b") + [""] | join("|"))
+ "pid:[0-9]{9}\\b"
) as $pattern |
reduce (inputs / "\n\n" | .[]) as $pass (0;
  # Counting valid passports
  if $pass | $req_fields - [ match($pattern; "g").string / ":" | .[0] ] | length > 0 then . else . += 1 end
)
