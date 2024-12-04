#!/usr/bin/env jq -n -R -f

[ inputs / "" ] | [.,.[0]|length] as [$H,$W] | [
  range($H) as $y | range($W) as $x | def z: select(.>=0);
  [
    (.[$y][$x] ),                # Center
    (.[$y-1|z][$x-1|z] // "." ), # Top Left
    (.[$y-1|z][ $x+1 ] // "." ), # Top Right
    (.[ $y+1 ][$x-1|z] // "." ), # Bottom Left
    (.[ $y+1 ][ $x+1 ] // "." )  # Bottom Right
  ] | add | select(
    . == "ASSMM" or . == "AMMSS" or . == "ASMSM" or . == "AMSMS"
  )
] | length
