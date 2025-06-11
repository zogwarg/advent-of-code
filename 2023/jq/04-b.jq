#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  inputs
  # Split winning numbers | card
  | split(" | ")
  # Get numbers, remove game id
  | .[] |= [ match("\\d+"; "g").string | tonumber ] | .[0] |= .[1:]
  # Set number of cards to 1, and further cards count
  | .[1] - (.[1] - .[0]) | [ 1, length ]
]

| { cards: ., i: 0, l: length } | until (.i == .l;
  # Get number for current card
  .cards[.i][0] as $num
  # Increase range of futher cards, by current number
  | .cards[.i + range(.cards[.i][1]) + 1 ][0] += $num
  | .i += 1
)

# Output total sum of cards
| [ .cards[][0] ] | add
