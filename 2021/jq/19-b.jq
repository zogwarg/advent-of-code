#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

#        Get vector difference          #
def delta: transpose | map(last - first);
#        Add offset to vector           #
def add(d): [.,d] | transpose | map(add);

#      List of possible "rotations"     #
def mats:
  (1,-1) as $a |
  (1,-1) as $b |
  (1,-1) as $c | (
    [[$a,0,0],[0,$b,0],[0,0,$c]],
    [[$a,0,0],[0,0,$b],[0,$c,0]],
    [[0,$a,0],[0,0,$b],[$c,0,0]],
    [[0,$a,0],[$b,0,0],[0,0,$c]],
    [[0,0,$a],[$b,0,0],[0,$c,0]],
    [[0,0,$a],[0,$b,0],[$c,0,0]]
  )
;
# Apply vector x matrix   #                            #
def mul($mat): [          #            │ a11 a21 a31 │ #
    range(3) as $j | ([   #      ╲╱    │ a12 a22 a32 │ #
    range(3) as $i |      #      ╱╲    │ a13 a23 a33 │ #
    .[$i] * $mat[$j][$i]  #                            #
  ]|add)                  # │v1 v2 v3│=│  r1  r2  r3 │ #
];                        #                            #

# Signature of vector, independent of rotation  #
def sig: "\(map(. * .|abs)|add)-\(map(abs)|add)";

#═══════════════════════════ Get Input ══════════════════════════════#

inputs | rtrimstr("\n") / "\n\n" | map(           #   Get beacon    #
  ./"\n" | .[1:] | map([scan("-?\\d+")|tonumber]) # Coordinates for #
) |                                               #   each scanner  #

[
  range(length) as $n | .[$n] | {
    $n,
    added: false, # Is added to map with coordinates from scanner 0 #
    done:  false, #   Has tried merging with all non-added maps     #
    points: [
      [[0,0,0]] + .| range(length) as $i | { # Add scanner position #
        pos: .[$i],
        #   Get signature of difference to every other point     #
        sig: [ range(length) as $j | [.[$i],.[$j]] | delta | sig ]
      }
    ]
  }
] | .[0].added = true |

#═══════════════════════════ Build Map ══════════════════════════════#

until (all(.[];.added);
  #--------------- Get first merge candidate -------------#
  [ first(.[] | select(.added and (.done|not))) ] as [$a] |
  [ first(
    #    Get matching point signatures      #
    (.[] | select(.added|not)) as $b | first(
        $a.points[] as $a
      | $b.points[] as $b
      | select(
            $a.sig
          | length-($a.sig-$b.sig|length)
          | . >=12
        )
      | [$a,$b|.pos]
    ) as [$x,$y] | # Empty if none matched  #

    mats as $mat | #  For each "rotation"   #

    [ # Select overlap, using x,y as new origin #
      [$a.points[]|[$x,.pos]|delta],            #
      [$b.points[]|[$y,.pos]|delta|mul($mat)]   #
    ]                                           #
    | select(.[0] - (.[0] - .[1]) | length >= 12)

    #   Using origin get required translation   #
    #   After correct "rotation" is applied     #
    | ([$y|mul($mat),$x]|delta) as $d

    | ( # Place all points into scanner 0 coord #
        $b | .points |= map({
          pos: (.pos|mul($mat)|add($d)),
          sig
        }) | .added = true
      )
  ) ] as [$b] | # Empty when no overlap remains #

  debug([$a,$b|.n]) |

  if ($b|not) then .[$a.n].done = true
              else .[$b.n]      = $b   end
) |

[ .[].points[0].pos ] | [   #   For every final scanner coordinate   #
  combinations(2)           #                                        #
  | select(.[0] < .[1])     # Check manhattan distance of every pair #
  | delta | map(abs) | add  #                                        #
] | max #  Output  Largest  #                                        #
