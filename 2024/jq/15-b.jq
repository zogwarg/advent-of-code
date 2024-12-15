#!/usr/bin/env jq -n -R -f

[ inputs / "" ] | (.[0]|length) as $N | # Assuming warehouse is square

#     Foreach move      #
reduce .[$N:][][] as $d (
  [
    {
      "@": first(. # Locate robot starting position
        | range(1;$N-1) as $y | range(1;$N-1) as $x
        | select(.[$y][$x] == "@") | [ (2*$x), $y ]
      )
    },
    ( . #   Only keep track of walls '#' and boxes 'O'    #
      | range($N) as $y | range($N) as $x
      | if .[$y][$x] | . == "." or . == "@" then empty else
          {"\([$x * 2,$y])": .[$y][$x] }
        end
    )
  ] | add;

  # Get robot position and board state #
  .["@"] as [$x,$y] |          . as $g |

  if $d == "<" then
    [ # Find connecting two-wide blocks to left
      [[$x,$y],["@"]] | recurse(first[0] -= 2 |
        if last[-1] | . == "@" or . == "O" then
          last = last + [ $g["\(first)"] ]
        else empty end #  Stop if null or '#' #
      )
    ] as $m |
    # We push if we stopped at null  #
    if ($m|last|last[-1] == null) then
      reduce $m[1:-1][] as [[$x,$y]] (            .["@"][0] -= 1;
        .["\([$x-1,$y])"] = .["\([$x,$y])"]| del(.["\([$x,$y])"])
      )
    end
  elif $d == ">" then
    [ # Find connecting two-wide blocks to right
      [[$x-1,$y],["@"]] | recurse(first[0] += 2|
        if  last[-1] | . == "@" or . == "O" then
          last = last + [ $g["\(first)"] ]
        else empty end #  Stop if null or '#' #
      )
    ] as $m |
    # We push if we stopped at null  #
    if ($m|last|last[-1] == null) then
      reduce $m[1:-1][] as [[$x,$y]] (             .["@"][0] += 1;
        .["\([$x+1,$y])"] = .["\([$x,$y])"] | del(.["\([$x,$y])"])
      )
    end
  elif $d == "v" then
    [ # Find connecting two-wide blocks, down.
      [[$x,$y],["@"]] | recurse(first[1] += 1|
        if  last[-1] == "@" then
          # '@' can connect with 2-wide blocks at offsets 0 and -1
          (., (first[0] -= 1)) |
          last = last + [ $g["\(first)"] ]
        elif last[-1] == "O" then
          # 'O' can connect with 2-wide blocks at offsets -1, 0, +1
          (., (first[0] -= 1), (first[0] += 1)) |
          last = last + [ $g["\(first)"] ]
        else empty end  #  Stop if null or '#' #
      )
    ] as $m |
    #  We push if no connecting blocks are walls '#'   #
    if all($m[]|last[]; . != "#" ) then .["@"][1] += 1 |
      ($m[1:]|map(select(last[-1])|last|=last)|unique) as $upd |
      del(.["\($upd[][0])"]) + (
        reduce $upd[] as [[$x,$y],$c] ({}; .["\([$x,$y+1])"] = $c )
      )
    end
  elif $d == "^" then
    [ # Find connecting 2-wide blocks going up
      [[$x,$y],["@"]] | recurse(first[1] -= 1|
        if  last[-1] == "@" then
          # '@' can connect with 2-wide blocks at offsets 0 and -1
          (., (first[0] -= 1)) |
          last = last + [ $g["\(first)"] ]
        elif last[-1] == "O" then
          # 'O' can connect with 2-wide blocks at offsets -1, 0, +1
          (., (first[0] -= 1), (first[0] += 1)) |
          last = last + [ $g["\(first)"] ]
        else empty end  #  Stop if null or '#' #
      )
    ] as $m |
    #  We push if no connecting blocks are walls '#'   #
    if all($m[]|last[]; . != "#" ) then .["@"][1] -= 1 |
      ($m[1:]|map(select(last[-1])|last|=last)|unique) as $upd |
      del(.["\($upd[][0])"]) + (
        reduce $upd[] as [[$x,$y],$c] ({}; .["\([$x,$y-1])"] = $c)
      )
    end
  else
    "Unexpected direction!" | halt_error
  end
) |

debug(# Pretty-print the final state of the warehouse #
  reduce (
    .["\(.["@"])"] = "@" | del(.["@"]) | to_entries[] |
    .key |= fromjson
  ) as {key:[$x,$y],value: $c} (
    [range($N) | [range(2*$N) | "." ]];
      if $c == "#" then .[$y][$x:$x+2] = ["#","#"]
    elif $c == "O" then .[$y][$x:$x+2] = ["[","]"]
                   else      .[$y][$x] = "@"   end
  )
  | .[] | add
)

#       Get SUM of box "GPS" coordinates      #
| with_entries( .
  | select(.value == "O")
  | .value = (.key|fromjson|.[0] + 100 * .[1])
) | [ .[] ] | add
