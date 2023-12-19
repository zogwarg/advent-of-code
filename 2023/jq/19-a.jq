#!/usr/bin/env jq -n -sR -f

inputs / "\n\n" | map(. / "\n" )

# Parse Rules
| .[0][] |= (
  scan("(.+){(.+)}")
  | .[1] |= (. / ",")
  | .[1][] |= capture("^((?<reg>.)(?<op>[^\\d]+)(?<num>\\d+):)?(?<to>[a-zA-Z]+)$")
  | ( .[1][].num | strings ) |= tonumber
  | {key: .[0], value: (.[1]) }
) | .[0] |= from_entries

# Parse musical parts
| .[1][] |= (
  scan("[^{}]+")
  | . / ","
  | .[] |= capture("^(?<key>.)=(?<value>\\d+)$")
  | .[].value |= tonumber
  | from_entries
)

# Store parsed inputs
| . as [$rules, $parts] |

def send_to($part; $r):
  if $r.op == "<" and $part[$r.reg] < $r.num then
    [ $part, $r.to ]
  elif $r.op == ">" and $part[$r.reg] > $r.num then
    [ $part, $r.to ]
  elif $r.op == null then
    [ $part, $r.to ]
  else empty end
;

[
  $parts[] | [. , "in" ] | recurse(
    # Terminate recursion on "Accept" or "Reject"
    if .[1] == "A" or .[1] == "R" then
      empty
    else
      # Recursively send part to first rule that applies
      first(send_to(.[0]; $rules[.[1]][]))
    end
    # Keep only parts in "Accepted" state
  ) | select(.[1] == "A")
    # Keep sub-score items
    | .[0][]
  # Produce total of all accepted sub-scores
] | add
