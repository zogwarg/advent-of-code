#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

{ # MFCSAM output
  "children": "3",
  "cats": "7",
  "samoyeds": "2",
  "pomeranians": "3",
  "akitas": "0",
  "vizslas": "0",
  "goldfish": "5",
  "trees": "3",
  "cars": "2",
  "perfumes": "1"
} as $hint |

# Get inputs, and parse line, with each remembered field
inputs | [ scan("Sue (\\d+):"), scan("([a-z]+): (\\d+)") ]

| .[0] |= {sue: .[0] }
| .[1:][] |= {(.[0]): (.[1])}

# Only keep remembered fields, that are in MFCSAM out
| map(select(keys | inside($hint | keys + ["sue"]) ))

# Add missing fields to entry
| $hint + add

# Keep exact match
| select(del(.sue) == $hint)

# Aunt Sue Nº
| .sue
