#!/usr/bin/env jq -n -R -f

[ inputs / "" ] | (.[0]|length) as $N | # Assuming warehouse is square

#     Foreach move      #
reduce .[$N:][][] as $d (
  {
     grid: .[0:$N],                        #       Grid is NxN       #
    robot: first(                          #                         #
      range($N) as $y | range($N) as $x |  #  Locate robot starting  #
      select(.[$y][$x] == "@") | [$x,$y]   #        position         #
    )
  }; .robot as [$x,$y] |

  def push($d):       #          A bit of regex abuse           #
    if $d == "<" then [  .grid[$y][0:$x+1]|add|scan("\\.O*@")   ]
  elif $d == ">" then [    .grid[$y][$x:]|add|scan("@O*\\.")    ]
  elif $d == "^" then [ [.grid[:$y+1][][$x]]|add|scan("\\.O*@") ]
  elif $d == "v" then [  [.grid[$y:][][$x]]|add|scan("@O*\\.")  ]
                      #     Only pushing into empty space       #
  else "Unexpected direction" | halt_error end                  ;

  push($d) as [$m] |

  # Updating the board and robot positions, if it's possible to push #
  #                         into empty space                         #
  if $d == "<" then
    if $m then .robot[0] -= 1 |          #  Easy horizontal update   #
      .grid[$y][$x+1-($m|length):$x+1] = ( $m / "" | .[1:] + .[0:1] )
    end
  elif $d == ">" then
    if $m then .robot[0] += 1 |          #  Easy horizontal update   #
      .grid[$y][$x:$x+($m|length)]     = ( $m / "" | .[-1:] + .[:-1])
    end
  elif $d == "^" then
    if $m then .robot[1] -= 1 |
      reduce ( $m|split("")[1:][] )  as $m (
        .grid[$y][$x] = "." | .i = ($m|-length); # Vertical zipping  #
        .i += 1 | .grid[$y+.i][$x] = $m          #   .["@"] = "."    #
      )
    end
  elif $d == "v" then
    if $m then .robot[1] += 1 |
      reduce ( $m|split("")[:-1][] ) as $m (
        .grid[$y][$x] = "." | .i = 0;            # Vertical zipping  #
        .i += 1 | .grid[$y+.i][$x] = $m          #   .["@"] = "."    #
      )
    end
  end
) |

[ . # Get SUM of box "GPS" coordinates #
  | range($N) as $y | range($N) as $x
  | select(.grid[$y][$x] == "O")
  | 100 * $y + $x
] | add
