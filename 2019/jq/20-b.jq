#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs ] | [ ., .[0] | length ] as [$H,$W] |

([
  range(1; $H-1) as $y | range(1; $W)  as $x |
  [ .[$y-1:$y+2][][$x-1:$x+2] ] | # 3x3 Boxes
  select(.[1][1:2] != "#") | # Center != Wall
  select(
    (
      all(.[0,2]|.[0:1],.[2:3];. == "#") # 4 Wall corners
      and (
        [
          .[0][1:2], .[1][0:1], .[1][2:3], .[2][1:2] |gsub("[^#]";".")
        ] != [".", "#", "#", "."] # 3x3 Box is not a vertical corridor
      )
      and (
        [
          .[0][1:2], .[1][0:1], .[1][2:3], .[2][1:2] |gsub("[^#]";".")
        ] != ["#", ".", ".", "#"] # 3x3 Box is not horizontal corridor
      )
    ) or (
      ( .[1][1:2] | test("[^#. ]")) and any(
        (.[1] | (.[0:1],.[2:3])), (.[0,2]|.[1:2]); #   Keep portals  #
        . == "."
      )
    )
  ) | [
    ($x, $y),   if .[1][1:2]|test("[A-Z]")
               and (( $x < 2 or $y < 2 ) or ($x>($W-3) or $y>($H-3)) )
              then [., "o"] # Outside portal
              elif .[1][1:2]|test("[A-Z]")
              then [., "i"] #  Inside portal
               end
  ]
]) as $nodes |

(reduce ($nodes[] | select(.[2][1][1:2] == ".")) as $node ({};
  def portal:
    (.[2]|[..|strings|scan("[oiA-Z]")]|add) as $p | if $p then $p end;
  def upd_next($next;$n):
    if $next then {r:"l", l:"r", u:"d", d:"u"} as $mir |
      .["\($node)"][$n] += [$next] |
      .["\($next[0])"]["\($mir[$n])"] += [[$node] + $next[-1:]]
    end
  ;
  def next($xy;$ax;$ob;$dir;$n):
    if .["\($node)"][$n] | not then
      (
        [ $nodes[]
          | select(
            .[$ax] == $xy[$ax] and ( .[$ob] - $xy[$ob] ) * $dir > 0
            )                   + [( .[$ob] - $xy[$ob] ) * $dir ]
        ] | min_by(.[-1]) | [(.[0:-1]|portal), .[-1]]
          | if ( .[0] | strings ) // false then .[-1] -= 1 end
      ) as $next | upd_next($next; $n)
    end
  ;
  # left
    if $node[2][1][0:1] != "#" then next($node[0:2]; 1; 0;-1; "l") end
  # right
  | if $node[2][1][2:3] != "#" then next($node[0:2]; 1; 0; 1; "r") end
  # up
  | if $node[2][0][1:2] != "#" then next($node[0:2]; 0; 1;-1; "u") end
  # down
  | if $node[2][2][1:2] != "#" then next($node[0:2]; 0; 1; 1; "d") end
  | debug({branch: $node})
)) as $branches |

([
  ($branches|keys[] | ( fromjson? // . ) | select(strings)) as $d |
  {"\($d)":(
    [
      (
        [$d, 0, [$d]] | recurse(
          if .[1] != 0 and (.[0]|type=="string") then empty else
            $branches["\(.[0])"][][] as [$next, $d] |
            if .[2]|index([$next]) then empty else
              [$next, (.[1] + $d), (.[2] + [$next])]
            end
          end
        ) | [.[0], .[1]]
          | select(.[1] != 0 and (.[0]|type=="string"))
      )
    ] | group_by(.[0])
      | map({"\(.[0][0])": min_by(.[1])[1]}) | sort_by(.[]) | add
      #    Also add oustide <-> inside connection   #  Remove extra #
      | . + {"\($d[0:2]+{o:"i",i:"o"}[$d[2:]])": 1} | del(.ZZi, .AAi)
  )}
] | add ) as $ptg | # Get portal to portal graph, recursive edition !

{
	q: [[["AAo",0],0]], d: { "\(["AAo",0])": 0 }
} |
until(isempty(.q[]) or .i > 1e6 or .d["\(["ZZo",0])"];
  .i += 1 | debug({i}) | (.q | min_by(.[1])) as [$u,$d]|
  .q = .q - [[$u, $d]] |
	reduce ( # Running Dijikstra on portal 2 portal graph
    ($ptg[$u[0]]|to_entries[]) as {key:$n,value:$v}|($d+$v) as $nd
    | select(
        if $u[1] == 0 then $n|test("..i|(AA|ZZ|\($u[0][0:2]))o") #
                      else $n|test("(AA|ZZ)")|not                #
                       end #---- Only keep valid transitions ----#
      )
    | (
          if $u[0][0:2] != $n[0:2]  # IF different portal label: #
        then [$n, $u[1]]            # Staying on the same level  #
        elif $n[2:] == "i"          #          OTHERWISE         #
        then [$n, ($u[1]-1)]        #           Go  Up           #
        else [$n, ($u[1]+1)]        #           Go Down          #
         end
      ) as $n
    | select( ( .d["\($n)"] // 10000 ) > $nd )
    |  [$n, $nd]
	) as [$n, $nd] (.; .d["\($n)"] = $nd | .q += [[$n, $nd]] )
)

# Output shortest path to ZZ
| .d["\(["ZZo",0])"]
