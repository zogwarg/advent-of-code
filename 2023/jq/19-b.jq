#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

inputs / "\n\n"

# Parse rules
| .[0] / "\n"
| .[] |= (
  scan("(.+){(.+)}")
  | .[1] |= (. / ",")
  | .[1][] |= capture("^((?<reg>.)(?<op>[^\\d]+)(?<num>\\d+):)?(?<to>[a-zA-Z]+)$")
  | ( .[1][].num | strings ) |= tonumber
  | {key: .[0], value: (.[1]) }
) | from_entries as $rules |

# Split part ranges into new ranges
def split_parts($part; $rule_seq):
  # For each rule in the sequence
  foreach $rule_seq[] as $r (
    # INIT = full range
    {f:$part};

    # OPERATE =
    # Adjust parts being sent forward to next rule
    if $r.reg == null then
      .out = [ .f , $r.to ]
    elif $r.op == "<" and .f[$r.reg][0] < $r.num then
      ([ .f[$r.reg][1], $r.num - 1] | min ) as $split |
      .out = [(.f | .[$r.reg][1] |= $split ), $r.to ] |
      .f[$r.reg][0] |= ($split + 1)
    elif $r.op == ">" and .f[$r.reg][1] > $r.num then
      ([ .f[$r.reg][0], $r.num + 1] | max ) as $split |
      .out = [(.f | .[$r.reg][0] |= $split), $r.to ]  |
      .f[$r.reg][1] |= ($split - 1)
    end;

    # EXTRACT = parts sent to other nodes
    # for recursion call
    .out | select(all(.[0][]; .[0] < .[1]))
  )
;

[ # Start with full range of possible sings in input = "in"
  [ {x:[1,4000],m:[1,4000],a:[1,4000],s:[1,4000]} , "in" ] |

  # Recusively split musical parts, into new ranges objects
  recurse(
    if .[1] == "R" or .[1] == "A" then
      # Stop recursion if "Rejected" or "Accepted"
      empty
    else
      # Recursively split
      split_parts(.[0];$rules[.[1]])
    end
    # Keep only part ranges in "Accepted" state
  ) | select(.[1] == "A") | .[0]

  # Total number if parts in each object is the product of the ranges
  | ( 1 + .x[1] - .x[0] ) *
    ( 1 + .m[1] - .m[0] ) *
    ( 1 + .a[1] - .a[0] ) *
    ( 1 + .s[1] - .s[0] )
  # Sum total number of possibly accepted musical parts
] | add
