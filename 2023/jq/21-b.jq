#!/usr/bin/env jq -n -R -f

# Utility functions
def assert($stmt; $msg): if $stmt == false then $msg | halt_error end;

[ inputs / "" ] as $grid |

# Get grid dimensions
( $grid    | length ) as $H |
( $grid[0] | length ) as $W |

assert($H == $W and $W % 2 == 1; "Unexpected grid dimensions \([$H,$W])") |

first(
  [range($W)] | combinations(2) | select($grid[.[1]][.[0]] == "S")
) as $start |

assert( # S can always be replaced in center with given asserts
  all($grid[$start[1]][],$grid[][$start[0]]; . == "." or . == "S");
  "Middle column and middle row should be empty."
) |

( # Dictionary of free squares, to be checked against mod W.
  [
    [range($W)]
    | combinations(2)
    | select($grid[.[1]][.[0]] | . == "S" or . == ".")
    | join(",")
    | {(.):true}
  ] | add
) as $free |

# Because S is in center and, the middle row and columns are empty
# If a square is reachable in the original in m steps (m < W)
# Then a square N boards away by Manhattan distance is reachable
# In N * W + m steps

# On an empty board, the steps are perfect squares 1,4,9,25,36,...
# With a filling diamond (x^2)
#     n
#    . .    The reachable area at step = N * W + m is:
#   .   .      A(step) = (N*W)^2 * (1 - number of # per diamiond )
#  .     .             + (N + 1) * ( squares reachable in "m" / 2)
# w       e
#  .     .
#   .   .   For steps with the same remainder, the area should follow
#    . .    The same qadratic formula. with taking the quotient as
#     s     a parameter. A(x) = a * x^2 + b * x + c
#
# This quadratic can be fully defined by finding the values for three
# Points, at the first three steps n, such as n ≡ 26501365 (mod W)
#
# Or = [rem, rem + W, rem + 2*W] -> Quotients [0, 1, 2]

reduce range(26501365 % $W + 2 * $W) as $i (
  {
    prev: {},
    curr: { ($start|join(",")): true },
    count: [0,1]
  };
  # Mod for checking candidates steps, in "free" space
  def mod($w):
    if . >= 0 then . % $w else ($w + ( . % $w ) ) % $w end
  ;
  debug("Step: \($i+1)") |

  .prev as $prev |
  .prev = .curr  |

  # Only updating outer edge, by preventing updates to squares
  # Seen in previous step, since accounting for parity
  # The total count of reached squares is the sum of the "rings"
  .curr = reduce (
    .curr
      | keys[] / "," | map(tonumber) as [$x,$y]
      | [$x+1,$y], [$x-1,$y], [$x,$y+1], [$x,$y-1]
      | select(map(mod($W)) | join(",") | $free[.])
      | join(",")
      | select($prev[.]|not)
  ) as $n ({}; .[$n] = true) |

  # Latest Count(N) = Outer Edge + Count(N-2)
  .count = .count + [ .count[-2] + (.curr|keys|length) ]
)

# Getting counts for [rem, rem + w, rem + 2 * w]
| [ .count[1:][26501365 % $W | (. + (0,1,2) * $W)] ] as [$A0,$A1,$A2] |

# Solving for b c:
# ------------------------------------------------
# a * 0 + b * 0 + c = A0 | c = A0
# a * 1 + b * 1 + c = A1 | a * 1 + b * 1 = A1 - A0
# a * 4 + b * 2 + c = A2 | a * 4 + b * 2 = A2 - A0
# ------------------------------------------------
# c = A0
# a = det_a / det = ((A1-A0)*2-(A2-A0)*1)/(-2)
# b = det_b / det = (1*(A2-A0)-4*(A1-A0))/(-2)
# ------------------------------------------------
# a = ( A0 + A2 ) / 2 - A1
# b = 2*A1 - ( A2 + 3*A0 ) / 2
# c = A0

# Outputing answer
(26501365/$W|floor) as $x |
(($A0+$A2)/2-$A1) * pow($x;2) + (2*$A1-($A2+3*$A0)/2) * $x + $A0
