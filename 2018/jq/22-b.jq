#!/usr/bin/env jq -n -sR -f

[ inputs | scan("\\d+") | tonumber ] as [$D, $X, $Y] |

( # Stack vertically
  if $X < $Y
  then [$X,$Y,16807,48271]
  else [$Y,$X,48271,16807]
  end
) as [$X, $Y, $MX, $MY] |

# "Reasonable" expansion,
[ ($X + 100), ($Y + 100) ] as [ $pX, $pY ] |

# Erosion Level and Type
def E($G): ( $G + $D ) % 20183;
def T: E(.) % 3;

# Initialize Geologic index for (x,0), (0,y), (X,Y) coordinates
[ range($pY+$pX) | [ range($pX) | 0 ] ] |
reduce range($pX)     as $x (.; .[0][$x] = ($x * $MX)) |
reduce range($pY+$pX) as $y (.; .[$y][0] = ($y * $MY)) |

# Fill diagonally
reduce (
  range(2;$pY+$pX)       as $y |
  range(1;[$y,$pX]|min)  as $x | [$x,$y-$x]
) as [$x,$y] (.;
  .[$y][$x] = E(.[$y][$x-1]) * E(.[$y-1][$x])
) | .[$Y][$X] = 0 |

# Get map of geographic index
[ .[0:$pY][]|map(T) ] as $geo |

{

  sub: ([
    range(1;$pY;10) as $slice | # Seperate map into slices of length 11
    reduce (                    # With overlapping lines, for later zip
        range($slice-1;[$slice+10,$pY-1]|min) as $y
      | range($pX-1) as $x      # Go right and down
      | [[$x,$y],[($x+1),$y]], [[$x,$y],[$x,($y+1)]]
    ) as [[$x,$y],[$nx,$ny]] (
      # Subgraph start
      {slice:[($slice-1),($slice+9)]} | debug({subgraph:.slice});

      [["t","g"],["g","n"],["t","n"]] as $valid_e | # Valid equip for G
      [$geo[$y][$x], $geo[$ny][$nx]]  as [$g,$ng] | # [G(curr),G(next)]
                        $valid_e[$g]  as [$a, $b] | # ValidEquip(curr)

      .graph["\([$x,$y,$a])"] += [[$x,$y,$b,7]] | # Link to other state
      .graph["\([$x,$y,$b])"] += [[$x,$y,$a,7]] | # at x,y with other E


      # Connect with neighbour cells: right and down, with shared equip
      reduce ($valid_e[$g]-($valid_e[$g]- $valid_e[$ng]) | .[]) as $c (
        .;
        .graph["\([ $x, $y,$c])"] += [[$nx,$ny,$c,1]] |
        .graph["\([$nx,$ny,$c])"] += [[ $x, $y,$c,1]]
      )
    ) | .graph[] |= unique |

    reduce ( .graph | keys[] ) as $key (.;
      .dist[$key] = { $key, value: 10000 }         | .q[$key] = true
    ) # Initialize - Distance                      | Q  -  dijikstra
  ] | .[0].dist["\([0,0,"t"])"] = { key: "\([0,0,"t"])", value: 0 }),
  sub_i: 0,
  prv_i: 0
} | (.sub | length - 1 ) as $end_i |

until (isempty(.sub[].q[]);    # Until Q is empty for all sub-graphs
  debug({sub_i}) | until (isempty(.sub[.sub_i].q[]); # sub-dijikstra
    (
      [ # Get node with minumum current distance
        .sub[.sub_i].dist[.sub[.sub_i].q|keys[]]
      ] | min_by(.value) | .key
    ) as $u |

    del( .sub[.sub_i].q[$u] ) |  # Remove from Q
    reduce (              # Check all neighbours
      ( .sub[.sub_i].graph[$u][]  | [.,"\(.[0:3])"] ) as [$v,$kv] |
      select(.sub[.sub_i].q[$kv]) | [$v,$kv] # That are still in Q.
    ) as [$v,$kv] (.;
        (.sub[.sub_i].dist[$u].value + $v[-1]) as $alt |
        if $alt < .sub[.sub_i].dist[$kv].value then
          .sub[.sub_i].dist[$kv]  =  {  key: $kv,  value: $alt  } |
          .sub[.sub_i].q[$kv] = true # Add back to Q, ahead of zip.
        end
    )
  ) |

  [.sub_i,.prv_i] as [$cur_i,$prv_i] |
  ( # Get the index of the next sub-graph to visit
    if $cur_i == 0 then 1 elif $cur_i == $end_i then $cur_i - 1 else
      if $prv_i < $cur_i then
        [
          "[\(range($pX)),\(( $cur_i ) * 10),\("t","g","n"|tojson)]" as $k | select(
            .sub[$cur_i-1].dist[$k].value < .sub[$cur_i].dist[$k].value
          ) | $k
        ] as $bef | debug({$bef}) |
        # Bounce back,  if common line with has been updated
        if ($bef|length > 0) then $prv_i else $cur_i + 1 end
      else
        [
          "[\(range($pX)),\(($cur_i+1) * 10),\("t","g","n"|tojson)]" as $k | select(
            .sub[$cur_i+1].dist[$k] < .sub[$cur_i].dist[$k].value
          ) | $k
        ] as $aft | debug({$aft}) |
         # Bounce back, if common line with has been updated
        if ($aft|length > 0) then $prv_i else $cur_i - 1 end
      end
    end
  ) as $next_i | ([$cur_i, $next_i]|max) as $zip_i |

  reduce ( # Update zip line with next subgraph when distance has been lowered
    "[\(range($pX+1)),\(($zip_i) * 10),\("t","g","n"|tojson)]" as $k | select(
      .sub[$cur_i].dist[$k].value < .sub[$next_i].dist[$k].value
    ) | $k
  ) as $k (.;
    .sub[$next_i].dist[$k] = .sub[$cur_i].dist[$k] |
    .sub[$next_i].q[$k] = true  # Add back to Queue.
  )

  # Update ( curr, prev ) subgraph idx
  | .sub_i = $next_i | .prv_i = $cur_i
)

| .sub[$Y/10].dist["\([$X,$Y,"t"])"].value
