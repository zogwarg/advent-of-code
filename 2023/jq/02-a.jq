#!/usr/bin/env jq -n -R -f

# For each game: Is 12 red cubes, 13 green cubes, and 14 blue cubes possible ?
# Line Format =
# Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
[
  # Splitting input game id and content
  inputs / ": " |
  # Saving id
  (.[0] / " " | .[1] | tonumber ) as $id |
  # Parsing game
  .[1] / "; " | [
    .[] / ", " | [ .[] / " " | {(.[1]): .[0] | tonumber} ] | add |
    # Is given sample possible ?
    .red <= 12 and .green <= 13 and .blue <= 14
  ] |
  # If all samples possible, return id, else 0
  if all then $id else 0 end
] |

# Return sum of all possible game ids
add
