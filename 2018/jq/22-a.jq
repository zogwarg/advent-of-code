#!/usr/bin/env jq -n -scrR -f

[ inputs | scan("\\d+") | tonumber ] as [$D, $X, $Y] |

( # Stack vertically
  if $X < $Y
  then [$X,$Y,16807,48271]
  else [$Y,$X,48271,16807]
  end
) as [$X, $Y, $MX, $MY] |

# Erosion Level and Type
def E($G): ( $G + $D ) % 20183;
def T: E(.) % 3;

# Initialize Geologic index for (x,0), (0,y), (X,Y) coordinates
[ range($Y+$X+2) | [ range($X+1) | 0 ] ] |
reduce range($X+1)    as $x (.; .[0][$x] = ($x * $MX)) |
reduce range($Y+$X+2) as $y (.; .[$y][0] = ($y * $MY)) |

# Fill diagonally
reduce (
  range(2;$Y+$X+2)       as $y |
  range(1;[$y,$X+1]|min) as $x | [$x,$y-$x]
) as [$x,$y] (.;
  .[$y][$x] = E(.[$y][$x-1]) * E(.[$y-1][$x])
) | .[$Y][$X] = 0 |

# Output Risk level
[ .[0:$Y+1][][0:$X+1][] | T ] | add
