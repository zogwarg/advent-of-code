#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Defining function to call, on each chain in the link
def move_link($final):
  [
    foreach ( # For each input produce stream of dir U2 -> U, U
      .[] | strings # Now with additional directions = ↖ ↗ ↙ ↘
    ) as $dir (
      #   Initial state   #
      {HT:[0,0],T:[0,0]}; #
      #####################

      # Get rotation for current, mapping pos to (0,1) or (1,1)
      def ht_rot:
          if .HT == [ 0, 1] then 0
        elif .HT == [ 1, 1] then 0
        elif .HT == [ 1, 0] then 1
        elif .HT == [ 1,-1] then 1
        elif .HT == [ 0,-1] then 2
        elif .HT == [-1,-1] then 2
        elif .HT == [-1, 0] then 3
        elif .HT == [-1, 1] then 3
        else "Unexpected HT: \(.HT)" | halt_error end
      ;

      # For rotation numner
      def dir_rot($rot):
        {
          "U":["U","L","D","R"],
          "↗":["↗","↖","↙","↘"],
          "R":["R","U","L","D"],
          "↘":["↘","↗","↖","↙"],
          "D":["D","R","U","L"],
          "↙":["↙","↘","↗","↖"],
          "L":["L","D","R","U"],
          "↖":["↖","↙","↘","↗"]
        }[. // "_"][$rot]
      ;

      # If HT = [0,0] no rotation or movement, just .HT update
      if .HT == [0,0] then
        .HT = {
          "U":[ 0, 1 ], "D":[ 0,-1 ], "L":[-1, 0 ], "R":[ 1, 0 ],
          "↖":[-1, 1 ], "↗":[ 1, 1 ], "↙":[-1,-1 ], "↘":[ 1,-1 ]
        }[$dir] |
        .D = null
      else
        # To check fewer condition, reducing state, to "U" or "UR"
        ht_rot as $rot |
        # Rotate HEAD
        .HT = [
          [ .HT[0], .HT[1] ],[-.HT[1], .HT[0] ],
          [-.HT[0],-.HT[1] ],[ .HT[1],-.HT[0] ]
        ][$rot] |
        # Rotate TAIL
        .T = [
          [ .T[0], .T[1] ],[-.T[1], .T[0] ],
          [-.T[0],-.T[1] ],[ .T[1],-.T[0] ]
        ][$rot] |
        # Rotate DIR
        ($dir | dir_rot($rot)) as $dir |

        if .HT == [0, 1] then
          # Update HEAD-TAIL vector
          .HT = {
            "U":[ 0, 1 ], "D":[ 0, 0 ], "L":[-1, 1 ], "R":[ 1, 1 ],
            "↖":[ 0, 1 ], "↗":[ 0, 1 ], "↙":[-1, 0 ], "↘":[ 1, 0 ]
          }[$dir] |
          # GET direction that this link goes in
          .D = {"U":"U","↖":"↖","↗":"↗"}[$dir] |

          # Update actual movement of tail
          .T[1] += {"U": 1,"↖": 1,"↗": 1}[.D//"."] // 0 |
          .T[0] += {"↖":-1,"↗": 1}[.D//"."] // 0
        elif .HT == [1, 1] then
          # Update HEAD-TAIL vector
          .HT = {
            "U":[ 0, 1 ], "D":[ 1, 0 ], "L":[ 0, 1 ], "R":[ 1, 0 ],
            "↖":[ 0, 1 ], "↗":[ 1, 1 ], "↙":[ 0, 0 ], "↘":[ 1, 0 ]
          }[$dir] |
          # GET direction that this link goes in
          .D = {"U":"↗","R":"↗","↗":"↗","↖":"U","↘":"R"}[$dir] |
          # Update actual movement of tail
          .T[1] += {"U": 1,"↗": 1,"↖": 1}[.D//"."] // 0 |
          .T[0] += {"R": 1,"↗": 1,"↘": 1}[.D//"."] // 0
        else "Unexpected HT: \(.HT)" | halt_error end |

        # Rotate HEAD back
        .HT = [
          [ .HT[0], .HT[1] ],
          [ .HT[1],-.HT[0] ],
          [-.HT[0],-.HT[1] ],
          [-.HT[1], .HT[0] ]
        ][$rot] |

        # Rotate TAIL back
        .T = [
          [ .T[0], .T[1] ],
          [ .T[1],-.T[0] ],
          [-.T[0],-.T[1] ],
          [-.T[1], .T[0] ]
        ][$rot] |

        # Rotate .D back
        .D |= dir_rot([0,3,2,1][$rot])

      end;

      # Extract D moves for  next link
      # Or tail positions if last link
      if $final then .T else .D end
    )
  ]
;

# Produce stream of directions from the head of the rope
[ inputs / " " | .[0] as $dir | range(.[1]|tonumber) | $dir ]

# Propgate movements down the chain
| move_link(false) | move_link(false) | move_link(false) # 1 2 3
| move_link(false) | move_link(false) | move_link(false) # 4 5 6
| move_link(false) | move_link(false) | move_link(true)  # 7 8 9

# Count number of unique positions covered by "9"
# The tail of the chain
| unique | length
