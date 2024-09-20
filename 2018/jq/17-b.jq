#!/usr/bin/env jq -n -rR -f

[ inputs | [       # v Get x line coordinate(s)
  (scan("x=[^,]+") | [ scan("\\d+")|tonumber ]),
  (scan("y=[^,]+") | [ scan("\\d+")|tonumber ])
]]                 # ^ Get y line coordinate(s)

#  Get new coordinates for from bounding box
| ([.[][0][]]|[min-1,max+1]) as [$xmin,$xmax]
| ([.[][1][]]|[ min , max ]) as [$ymin,$ymax]
|   .[][0][] -= $xmin   |   .[][1][] -= $ymin
# Initialize state: w->water, s->spread_water
| {l:.,s:[[(500-$xmin),0]],w:[],sw:[],ds:[]}|
#  l->lines, s:curr_sources, ds->dead_sources

#   Display the current grid state
def display:  . as {$l,$w,$sw,$ds} |
  reduce $l[] as [[$x1,$x2],[$y1,$y2]] (
    [   # Initializing grid
        range(1 + $ymax - $ymin)
    | [ range(1 + $xmax - $xmin) | "." ]
    ];
    # Drawing horizontal and vertical lines
    if $x2 then .[$y1][range($x1;$x2+1)] = "#"
           else .[range($y1;$y2+1)][$x1] = "#" end
  ) |
  reduce $w[] as [[$x1,$x2],[$y1],[$_],$d] (.;
    if $x2 then # Drawing still water lines
      .[range($y1;$y1+$d)][range($x1;$x2+1)] = "~"
    end
  ) |
  reduce $sw[] as [[$x1,$x2],[$y1,$y2]](.;
    if $x2 then # Drawing spreading water lines
      .[$y1][range($x1;$x2+1)] = "|"
    end
  ) |
  reduce ($ds | unique[]) as [$x,$y] (.;
    if .[$y][$x] == "." then
      ( [ .[$y][$x] = "|" | .[][$x] ]
        | join("")[$y:]| match("^[|].*?(?=[~#|]|$)")
      ) as {offset:$o,length:$l} |

      ( # Pour line from dead source
        .[range($o+$y;$o+$y+$l)][$x]
      ) |= (if . != "#" then "|" else "!" end)
    end
  )
  # Pretty print
  | .[] | join("")
;

# Pour every source
until (isempty(.s[]);
  def drop($sx;$sy):
    (
      def _drop($line):
        $line as [[$lx1,$lx2],[$ly1,$ly2]] |
        if ($lx2 and ($ly1  < $sy or $lx2 < $sx or $lx1 > $sx ))
        or ($ly2 and ($lx1 != $sx or $ly1 < $sy )) then empty
        else {y: ($ly1 - 1), l: $line} end
      ;
      [ # Drop from source to highest line
        ( _drop( .l[]) | .t =  "l" ), # If       line      will spread
        ( _drop( .w[]) | .t =  "w" ), # If       water     will  raise
        ( _drop(.sw[]) | .t = "sw" ), # If spreading water will  abort
        empty
      ] | sort_by(.y,-(.l[0]| length))[0:1]
    ) as [{$y,l:[[$lx1,$lx2],[$ly1,$ly2]],$t}] |

    (
      def _connect($cline): # Test if line is connected to others
        $cline as [[$cx1,$cx2],[$cy1,$cy2]] |
          if ($cx2 and $lx2) or ($cy2 and $ly2) or $t!="l" then empty
        elif ($cx2 and [$cx1,$cy1] == [$lx1,$ly1])
          or ($lx2 and [$lx1,$ly1] == [$cx1,$cy1]) then ["F", $cline]
        elif ($cx2 and [$cx1,$cy1] == [$lx1,$ly2])
          or ($lx2 and [$lx1,$ly1] == [$cx1,$cy2]) then ["L", $cline]
        elif ($cx2 and [$cx2,$cy1] == [$lx1,$ly1])
          or ($lx2 and [$lx2,$ly1] == [$cx1,$cy1]) then ["7", $cline]
        elif ($cx2 and [$cx2,$cy1] == [$lx1,$ly2])
          or ($lx2 and [$lx2,$ly1] == [$cx1,$cy2]) then ["J", $cline]
        else empty end
      ;
      [ _connect(.l[]) ]
    ) as $c | def _sumc: map(.[0]|tostring)|sort|add;

      if $t == "w" then   # If hitting water raise water line by one
      .wl = [[$lx1,$lx2], [$ly1-1], [$sx,$sy], 1] | .w  = .w + [.wl]
    elif $c == []  then . # If unconnected pass (assumption on head)
    elif $lx2 and ($c | _sumc == "JL") then
      # Hitting bottom of a bucket, spreading  a water line to walls
      .wl = [[$lx1+1,$lx2-1],[$ly1-1],[$sx,$sy],1]| .w  = .w + [.wl]
    elif $lx2 and ($c | _sumc | test("^(7F)?$")) then
      # Hitting dome, adding water spread a new sources
      .sw += [[[$lx1,$lx2], [$ly1-1], [$sx,$sy],"_"]] |
      .s = [
        [($lx1-1),($ly1-1)],
        [($lx2+1),($ly1-1)]
      ] + .s
    elif $ly2 and ($c | _sumc | test("^[LJ]?$")) then
      # Hitting head, adding 1 tile if spreading water
      .sw += [[[$lx1,$lx1],[$ly1-1], [$sx,$sy],"_"]] |
      .s = [
        [($lx1-1),($ly1-1)],
        [($lx1+1),($ly1-1)]
      ] + .s
    else # Assuming no L7 or FJ
      "drop_error" | halt_error
    end | .ds += [[$sx,$sy]] # Until maybe revived, source is dead
  ;

  def raise($wl): $wl as [[$wx1,$wx2],[$wy],[$sx,$sy]] |
    def _raise($line):
      $line as [[$lx1,$lx2],[$ly1,$ly2]] |
      if $sy > $ly1 then empty # Ignore lines too low
      elif $ly2 and $wx1 == $lx1+1
                and $wy  >= $ly1 and $wy <= $ly2 then
        { # Overflow left
          y: ($ly1 - 1),
          w:[[$wx1,$wx2],[$ly1],[],($wy - $ly1)],
          t:"l"
        }
      elif $ly2 and $wx2 == $lx1-1
                and $wy >= $ly1 and $wy <= $ly2  then
        { # Overflow right
          y: ($ly1 - 1),
          w:[[$wx1,$wx2],[$ly1],[],($wy - $ly1)],
          t:"r"
        }
      elif $ly2 and $wy > $ly2 and $wx1 < $lx1 and $wx2 > $lx1 then
        { # Bump into vertical line
          y: ($ly2 + 1),
          wl: (
            if $sx < $lx1 then
              [[$wx1,($lx1-1)],[$ly2],[$sx,$sy],($wy-$ly2)]
            else
              [[($lx1+1),$wx2],[$ly2],[$sx,$sy],($wy-$ly2)]
            end
          ),
          w: (
            if $sx < $lx1 then
              [
                [[ $lx1   ,$lx1],[$ly2+1],["_"],($wy-$ly2-1)],
                [[($lx1+1),$wx2],[$ly2+1],[" "],($wy-$ly2-1)]
              ]
            else
              [
                [[$lx1, $lx1   ],[$ly2+1],["_"],($wy-$ly2-1)],
                [[$wx1,($lx1-1)],[$ly2+1],[" "],($wy-$ly2-1)]
              ]
            end
          ),
          t:"v"
        }
      elif $lx2 and $wy > $ly1 and $wx1 < $lx1 and $wx2 > $lx2 then
        { # Bump into horizontal line
          y: ($ly1 + 1),
          wl: (
            if $sx < $lx1 then
              [[$wx1,($lx1-1)],[$ly1],[$sx,$sy],($wy-$ly1)]
            else
              [[($lx2+1),$wx2],[$ly1],[$sx,$sy],($wy-$ly1)]
            end
          ),
          w: (
            if $sx < $lx1 then
              [
                [[ $lx1   ,$lx2],[$ly1+1],["_"],($wy-$ly1-1)],
                [[($lx2+1),$wx2],[$ly1+1],[" "],($wy-$ly1-1)]
              ]
            else
              [
                [[$lx1, $lx2   ],[$ly1+1],["_"],($wy-$ly1-1)],
                [[$wx1,($lx1-1)],[$ly1+1],[" "],($wy-$ly1-1)]
              ]
            end
          ),
          t:"u"
        }
      else
        empty
      end
    ;
    def merge_sw($nx1;$nx2;$ny;$nd):
      if any(
        .sw[]; # Ignore the lines that can't be merged
        . as [ [$wx1, $wx2], [$wy], [$sx, $sy], $t ] |
        $wy == $ny and ($wx1 == $nx2 or $wx2 == $nx1)
      ) | not then

        [ # Update left and right of the spreading line
          (.l[] | select(.[0][1]) | select(.[0][1] == $nx1) |
          select(.[1] == [$ny+1]) | .[0][0]), $nx1
        ] as [$nx1] |
        [
          (.l[] | select(.[0][1]) | select(.[0][0] == $nx2) |
          select(.[1] == [$ny+1]) | .[0][1]), $nx2
        ] as [$nx2] | # Depending connecting lines

        # Update spreading water and fresh sources
        .sw += [[[$nx1,$nx2],[$ny],[$sx,$sy],$nd]] |
        .s = [
          if $nd == "_" then
            [$nx1-1,$ny],[$nx2+1,$ny]
          elif $nd == "<" then
            [$nx1-1,$ny]
          elif $nd == ">" then
            [$nx2+1,$ny]
          else
            "merge_sw_error" | halt_error
          end
        ] + .s
      else
        [ # Select the lines that touch the current one
          .sw[] |  . as [ [$wx1, $wx2], [$wy], [$sx, $sy], $t ] |
          select($wy == $ny and ($wx1 == $nx2 or $wx2 == $nx1)) |
          . + [ if $wx1 == $nx2 then ">" else "<" end ]
        ] as $sw |

        # Remove spreading lines to be merged
        .sw = [ .sw[] | select(all(
          $sw[] as [$x,$y] | .[0] != $x or .[1] != $y; .
        ))]|

        [ # Get new merged spreading lines
          [([$sw[][0][0],$nx1]|min),([$sw[][0][1],$nx2]|max)],
          $sw[0][1],
          ([$sw[][2]]|min_by(.[1],.[0])),
          ({
            ">_|>": ">",
            "<_|<": "<",
            "><|>": "d",
            "<>|<": "d",
            "__|>": "<",
            "__|<": ">",
            "_>|<": ">>",
            "_<|>": "<<"
          }[
            $nd+([$sw[][3]]|join(""))+"|"+([$sw[][4]]|join(""))
          ])
        ] as $nw |

        # Assuming listed cases are the only ones
        if $nw[3]|not then "nw_error" | halt_error end |
        # In this case no need to update source
        if $nw[3]|test("^[<>]$") then .sw += [$nw]
        # Creating one new source to the right
        elif $nw[3] == ">>" then
          .sw += [$nw | .[3] = ">"] |
          .s = [[$nx2+1,$ny]] + .s
        # Creating one new source to the left
        elif $nw[3] == "<<" then
          .sw += [$nw | .[3] = "<"] |
          .s = [[$nx1-1,$ny]] + .s
        else
          # Spreading water becomes still
          .w += [$nw|.[-1] = 1] |
          # Restoring dead source
          .s = [$nw[2]] + .s
        end
      end
    ;

    # Raise water, and keep events at lowest y
    [ _raise(.l[]) ]   as $r |
    ( [$r[].y] | max ) as $y |
    ([ $r[] | select(.y == $y) ] | sort_by(.t)) as $r |
    ([$r[].t]|add) as $rt |

    if $rt | test("lr")  then # Climbed both walls
      $r as [{$w}] | $w as [[$wx1,$wx2],[$wy]] |
      .wl  = null |
      .w  += [$w] |
      merge_sw($wx1-1;$wx2+1;$wy-1;"_")
    elif $rt | test("l") then # Climbed left wall
      $r as [{$w}] | $w as [[$wx1,$wx2],[$wy]] |
      .wl  = null |
      .w  += [$w] |
      merge_sw($wx1-1;$wx2;$wy-1;"<")
    elif $rt | test("r") then # Climbed right wall
      $r as [{$w}] | $w as [[$wx1,$wx2],[$wy]] |
      .wl  = null |
      .w  += [$w] |
      merge_sw($wx1;$wx2+1;$wy-1;">")
    elif $rt | test("[uv]") then # Hit line early
      .wl = (
        reduce $r[1:][].wl as [[$x1,$x2]] ($r[0].wl;
          .[0][0] = ([.[0][0],$x1] | min_by($sx - .)) |
          .[0][1] = ([.[0][1],$x2] | min_by(. - $sx))
        )
      ) | (
        reduce $r[1:][].w[] as [[$x1,$x2],[$y],[$t],$d] (
          $r[0].w; .
        )
      ) as $w |
      .w += ($w + [.wl]) | .s = [[$sx,$sy]] + .s
    end
  ;
  # One drop and raise iteration per source
  .i+=1              | debug({i}) |
  .s[0] as [$sx,$sy] | .s=.s[1:]  |
    drop($sx; $sy)   | if .wl then raise(.wl) end
)

# Lazily counting the "still" water via display method
| reduce (display / "" | .[] | select(test("[~]"))) as $i (0;.+1)
