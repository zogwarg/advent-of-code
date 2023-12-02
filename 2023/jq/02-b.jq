#!/usr/bin/env jq -n -R -f

# Line Format =
# Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
[
  # Splitting input game id and content
  inputs / ": " |
  # Parsing game
  .[1] / "; " |
    [ .[] / ", " | [ .[] / " " | {(.[1]): .[0] | tonumber} ] | add ] |
    # Getting minimum required mumber for each color,
    # and computing the power
    {
      r: ([.[].red]   | max),
      g: ([.[].green] | max),
      b: ([.[].blue]  | max)
    } | .r * .g * .b
] |

# Return sum of all powers
add
