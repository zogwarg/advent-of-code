#!/usr/bin/env jq -n -rR -f

# Utility
def group_of($n):
  . as $in | [ range(0;length;$n) | $in[.:(.+$n)] ]
;

# Make display to letter map
(
  [
    # Font map - Some values are assumed
    # A      B        C        D        E
    ".##..", "###..", ".##..", "###..", "####.",
    "#..#.", "#..#.", "#..#.", "#..#.", "#....",
    "#..#.", "###..", "#....", "#..#.", "###..",
    "####.", "#..#.", "#....", "#..#.", "#....",
    "#..#.", "#..#.", "#..#.", "#..#.", "#....",
    "#..#.", "###..", ".##..", "###..", "####.",
    # F      G        H        I        J
    "####.", ".##..", "#..#.", ".###.", "..##.",
    "#....", "#..#.", "#..#.", "..#..", "...#.",
    "###..", "#....", "####.", "..#..", "...#.",
    "#....", "#.##.", "#..#.", "..#..", "...#.",
    "#....", "#..#.", "#..#.", "..#..", "#..#.",
    "#....", ".###.", "#..#.", ".###.", ".##..",
    # K       L        M       N        O
    "#..#.", "#....", ".#.#.", "#...#", ".##..",
    "#.#..", "#....", "#####", "##..#", "#..#.",
    "##...", "#....", "#.#.#", "#.#.#", "#..#.",
    "#.#..", "#....", "#.#.#", "#.#.#", "#..#.",
    "#.#..", "#....", "#...#", "#..##", "#..#.",
    "#..#.", "####.", "#...#", "#...#", ".##..",
    # P      Q        R        S        T
    "###..", ".##..", "###..", ".###.", "#####",
    "#..#.", "#..#.", "#..#.", "#....", "..#..",
    "#..#.", "#..#.", "#..#.", "#....", "..#..",
    "###..", "#.##.", "###..", ".##..", "..#..",
    "#....", "#..#.", "#.#..", "...#.", "..#..",
    "#....", ".##.#", "#..#.", "###..", "..#..",
    # U      V        W        X        Y
    "#..#.", "#...#", "#...#", "#...#", "#...#",
    "#..#.", "#...#", "#...#", ".#.#.", "#...#",
    "#..#.", "#...#", "#.#.#", "..#..", ".#.#.",
    "#..#.", ".#.#.", "#.#.#", ".#.#.", "..#..",
    "#..#.", ".#.#.", "#####", "#...#", "..#..",
    ".##..", "..#..", ".#.#.", "#...#", "..#.."
  ] | [
    (
      # Reshape input into proper keys
      [ group_of(5) | transpose[] | group_of(6)[] | add ] |
      [ group_of(5) | transpose[][] ]
    ),
    ( "ABCDEFGHIJKLMNOPQRSTUVWXY" / "")
  ] | transpose | map({(.[0]):.[1]}) | add

  # Add missing Z
  | .[
    [
      "####.",
      "...#.",
      "..#..",
      ".#...",
      "#....",
      "####."
    ] | add
  ] = "Z"
) as $to_letter |

# Get final layer
reduce(
  # Take all inputs
  inputs | gsub("1";"#") | gsub("0";".") / ""
  # Group up pixels by layer
  | group_of(25 * 6)[]
) as $layer ([range(25 * 6) | "2"];
  [., $layer] | transpose | map(
    if .[0] != "2" then .[0] else .[1] end
  )
)

# Reshape final layer to letter block
| group_of(5) | group_of(5) | transpose | [
  .[] | map(add|debug) | ("-----" | debug) as $d |
  # Letter block -> letter
  $to_letter[add] // "_"
]

# Output text on final layer
| add
