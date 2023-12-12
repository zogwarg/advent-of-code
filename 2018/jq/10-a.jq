#!/usr/bin/env jq -n -rR -f

# Get list of points as <x,y,dx,dy>
[ inputs | [ scan("-?\\d+") | tonumber ]] |


# Check all the steps that minimize the distance, close to "zero"
([ # "Cheat" by only checking 3 points
  .[0:3][] | [
    [range(.[0];.[2]*10;.[2])], # Generate list of x positions for each step
    [range(.[1];.[3]*10;.[3])]  # Generate list of y positions for each step
  ]
  | transpose  | map(select(.[0] and .[1]))      #Zip X and Y as (x,y) pairs
  | to_entries | min_by(.value|map(abs)|add).key # Get step idx, of min dist
  # Output smaller range of steps within which the the total distance is min
] | [min,max]) as [ $steps_min, $steps_max] |

([
  range($steps_min;$steps_max) as $steps | # For "steps"  in candidate range
  map(
    . as [$x,$y,$i,$j]|[[$x,$y],[$i,$j]] | # Translate all points by n steps
    transpose | map(.[0] + $steps *.[1])
  )
  | [max, $steps] # For each candidate number of steps, get point with x_max
] | min) as [$_, $steps] | # We chose the number of steps where x_max is min

# Move all points to correct position
map(
  . as [$x,$y,$i,$j]|[[$x,$y],[$i,$j]]| transpose| map(.[0] + $steps * .[1])
) |

# Change coordinates, with (xmin,ymin) -> (0,0)
([.[][0]]|[min,max]) as [$xmin,$xmax]|([.[][1]]|[min,max]) as [$ymin,$ymax]|
reduce ( .[] | .[0] -= $xmin | .[1] -= $ymin ) as [$x, $y] (
  [range(1+$ymax-$ymin)|[range(2+$xmax-$xmin)|" "]];
  .[$y][$x] = "#"
) |

# This block outputs the text, as graphical display
def group_of($n): . as $in | [ range(0;length;$n) | $in[.:(.+$n)] ];

( # Building to_letter map for automatic text detection
  # Some of the letters are assumed, a mismatch will appear as "_"
  # And you can check the debug output, and substitue the letter in
  # This array

  [ # A         # E         # K         # P         # U
    "  ####  ", " ###### ", " #    # ", " #####  ", " #    # ",
    " #    # ", " #      ", " #   #  ", " #    # ", " #    # ",
    " #    # ", " #      ", " #  #   ", " #    # ", " #    # ",
    " #    # ", " #      ", " # #    ", " #    # ", " #    # ",
    " ###### ", " #####  ", " ##     ", " #####  ", " #    # ",
    " #    # ", " #      ", " # #    ", " #      ", " #    # ",
    " #    # ", " #      ", " #  #   ", " #      ", " #    # ",
    " #    # ", " #      ", " #   #  ", " #      ", " #    # ",
    " #    # ", " #      ", " #    # ", " #      ", " #    # ",
    " #    # ", " #      ", " #    # ", " #      ", "  ####  ",
    # B         # G         # L         # Q        # V
    " #####  ", "  ####  ", " #      ", "  ####  ", "#     # ",
    " #    # ", " #    # ", " #      ", " #    # ", "#     # ",
    " #    # ", " #      ", " #      ", " #    # ", "#     # ",
    " #    # ", " #      ", " #      ", " #    # ", " #   #  ",
    " #####  ", " #  ### ", " #      ", " #    # ", " #   #  ",
    " #    # ", " #    # ", " #      ", " #    # ", " #   #  ",
    " #    # ", " #    # ", " #      ", " # #  # ", "  # #   ",
    " #    # ", " #    # ", " #      ", " #  # # ", "  # #   ",
    " #    # ", " #    # ", " #      ", " #   #  ", "  # #   ",
    " #####  ", "  ####  ", " ###### ", "  ### # ", "   #    ",
    # C         # H        # M          # R        # W
    "  ####  ", " #    # ", "#     # ", " #####  ", "#     # ",
    " #    # ", " #    # ", "##   ## ", " #    # ", "#     # ",
    " #      ", " #    # ", "##   ## ", " #    # ", "#     # ",
    " #      ", " #    # ", "# # # # ", " #    # ", "#     # ",
    " #      ", " ###### ", "# # # # ", " #####  ", "#  #  # ",
    " #      ", " #    # ", "#  #  # ", " ##     ", "# # # # ",
    " #      ", " #    # ", "#     # ", " # #    ", "# # # # ",
    " #      ", " #    # ", "#     # ", " #  #   ", "##   ## ",
    " #    # ", " #    # ", "#     # ", " #   #  ", "##   ## ",
    "  ####  ", " #    # ", "#     # ", " #    # ", "#     # ",
    # D        # I          # N         # S         # X
    " ####   ", "####### ", " #    # ", "  ####  ", " #    # ",
    " #   #  ", "   #    ", " ##   # ", " #    # ", " #    # ",
    " #    # ", "   #    ", " ##   # ", " #      ", "  #  #  ",
    " #    # ", "   #    ", " # #  # ", " #      ", "  #  #  ",
    " #    # ", "   #    ", " # #  # ", "  ##    ", "   ##   ",
    " #    # ", "   #    ", " #  # # ", "    ##  ", "   ##   ",
    " #    # ", "   #    ", " #  # # ", "      # ", "  #  #  ",
    " #    # ", "   #    ", " #   ## ", "      # ", "  #  #  ",
    " #   #  ", "   #    ", " #   ## ", " #    # ", " #    # ",
    " ####   ", "####### ", " #    # ", "  ####  ", " #    # ",
    # E         # J         # O        # T         # Y
    " ###### ", "      # ", "  ####  ", "####### ", "#     # ",
    " #      ", "      # ", " #    # ", "   #    ", "#     # ",
    " #      ", "      # ", " #    # ", "   #    ", " #   #  ",
    " #      ", "      # ", " #    # ", "   #    ", "  # #   ",
    " #####  ", "      # ", " #    # ", "   #    ", "   #    ",
    " #      ", "      # ", " #    # ", "   #    ", "   #    ",
    " #      ", "      # ", " #    # ", "   #    ", "   #    ",
    " #      ", " #    # ", " #    # ", "   #    ", "   #    ",
    " #      ", " #    # ", " #    # ", "   #    ", "   #    ",
    " ###### ", "  ####  ", "  ####  ", "   #    ", "   #    "
  ] |

  [ [ group_of(5) | transpose | map(group_of(10))[][] | add ],
    ( "ABCDEFGHIJKLMNOPQRSTUVWXY" / "" )
  ]
  | transpose | map({(.[0]):.[1]})
  | add | .[
      # Z
      " ###### "
    + "      # "
    + "      # "
    + "     #  "
    + "    #   "
    + "   #    "
    + "  #     "
    + " #      "
    + " #      "
    + " ###### "
  ] = "Z"
) as $to_letter |

[
  [ .[] | [" "] + . | group_of(8) ] | transpose[]|("        " | debug) as $d
  | [ .[] | add | debug ] | add | $to_letter[.] // "_"
] | add
