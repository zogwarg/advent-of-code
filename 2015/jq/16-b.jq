#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

{ # MFCSAM output
  "children": 3,
  "cats": 7,
  "samoyeds": 2,
  "pomeranians": 3,
  "akitas": 0,
  "vizslas": 0,
  "goldfish": 5,
  "trees": 3,
  "cars": 2,
  "perfumes": 1
} as $hint |

# Get inputs, and parse line, with each remembered field
inputs | [ scan("Sue (\\d+):"), scan("([a-z]+): (\\d+)") ]

| .[0] |= {sue: .[0] }
| .[1:][] |= {(.[0]): (.[1]|tonumber)}

# Only keep remembered fields, that are in MFCSAM out
| map(select(keys | inside($hint | keys + ["sue"]) ))

# Add missing fields to entry
| $hint + add |

select(
  # Fields which are range indications
  .cats        >= $hint.cats        and
  .trees       >= $hint.trees       and
  .pomeranians <= $hint.pomeranians and
  .goldfish    <= $hint.goldfish    and

  # Fields which are exact matches
  .children    == $hint.children    and
  .samoyeds    == $hint.samoyeds    and
  .akitas      == $hint.akitas      and
  .vizslas     == $hint.vizslas     and
  .cars        == $hint.cars        and
  .perfumes    == $hint.perfumes    and

  # Exclude original result
  del(.sue)    != $hint
)

# Aunt Sue Nº
| .sue
