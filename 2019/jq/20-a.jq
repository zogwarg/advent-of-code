#!/usr/bin/env jq -n -R -f

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
  ) | [ ($x, $y), . ]
]) as $nodes |

(reduce ($nodes[] | select(.[2][1][1:2] == ".")) as $node ({};
  def portal:(.[2]|[add|scan("[A-Z]")]|add) as $p|  if $p then $p end;
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
  )}
] | add ) as $ptg | # Get portal to portal graph

{
	q: [["AA",0]], d: { AA: 0 }
} |
until(isempty(.q[]) or .i > 1e6;    .i += 1 | debug({i}) |
	(.q | min_by(.[1])) as [$u, $d] | .q = .q - [[$u, $d]] |
	reduce ( # Running Dijikstra on portal 2 portal graph
		( $ptg[$u] | to_entries[] ) as {key: $n, value: $v}
		| ($d + $v + 1) as $nd  # Add 1 for each portal use
		| select( ( .d[$n] // 10000 ) > $nd ) | [ $n, $nd ]
	) as [$n, $nd] (. ; .d[$n] = $nd | .q +=  [[$n, $nd]] )
)

# Output shortest path to ZZ
| .d.ZZ - 1
