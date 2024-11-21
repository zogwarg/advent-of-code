#!/usr/bin/env jq -n -R -f

[ inputs ] | [ ., .[0] | length ] as [$H,$W] |

([
  range(1; $H-1) as $y | range(1; $W)  as $x |
  [ .[$y-1:$y+2][][$x-1:$x+2] ] | # 3x3 Boxes
  select(.[1][1:2] != "#") | # Center != Wall
  select(
    (
      all(.[0,2]|.[0:1],.[2:3];. == "#" or . == "@") # 4 Wall corners
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
    ) or ( .[1][1:2] | test("[^@#.]") )  # Keys and doors, omit Start.
  ) | [
    ($x, $y),
      # Create new starting positions 1 through 4, around central "@"
      if .[0][0:1] == "@" then .[0] = "###" | .[1] = "#4" + .[1][-1:]
    elif .[0][2:3] == "@" then .[0] = "###" | .[1] = .[1][:-2] + "3#"
    elif .[2][0:1] == "@" then .[2] = "###" | .[1] = "#2" + .[1][-1:]
    elif .[2][2:3] == "@" then .[2] = "###" | .[1] = .[1][:-2] + "1#"
     end
  ]
]) as $nodes |

(reduce $nodes[] as $node ({};
  def upd_next($next;$n):
    if $next then {r:"l", l:"r", u:"d", d:"u", s:"s"} as $mir |
      .["\($node)"][$n] += [$next] |
      .["\($next[0:3])"]["\($mir[$n])"] += [$node + $next[-1:]]
    end
  ;
  def next($xy;$ax;$ob;$dir;$n):
    if .["\($node)"][$n] | not then
      (
        [ $nodes[]
          | select(
            .[$ax] == $xy[$ax] and ( .[$ob] - $xy[$ob] ) * $dir > 0
            )                   + [( .[$ob] - $xy[$ob] ) * $dir ]
        ] | min_by(.[-1])
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
)) as $branches |

([
  ($branches|keys[] | fromjson | select(.[2][1][1:2] != "." )) as $d |
  {"\($d[2][1][1:2])":(
    [
      (
        [$d, 0, [$d]] | recurse(
                  # Stop at when reaching next key or door
          if .[1] != 0 and .[0][2][1][1:2] != "." then empty else
                 $branches["\(.[0][0:3])"][][] as $next |
                            # Don't step back
            if .[2] | index([$next[0:3]]) then empty else
              [ $next[0:3], (.[1]+$next[3]), (.[2]+[$next[0:3]]) ]
            end
          end
        ) | select(.[0][2][1][1:2] != "." and .[1] > 0) # Discard "."
          | [.[0][2][1][1:2], .[1]] # Format: ["X", distance]
      )
    ] | group_by(.[0]) | map({"\(.[0][0])": min_by(.[1])[1] }) | add
  )}
] | add ) as $kdg | # Get keys and doors graph

def  is_key($k):  $k|test("[a-z]");              # 🔑 #
def is_door($k):  $k|test("[A-Z]");              # 🚪 #
def cnt($ks;$k): $ks|index([$k|ascii_downcase]); # 🔓 #

def to_keys($pos; $ks):
  {q: [[$pos,0]], d: {"\($pos)": 0 }} | until (isempty(.q[]);
    .q[0] as [$pos, $d] | .q = .q[1:] | # BFS search to keys
    reduce (
      ( $kdg[$pos] | to_entries[] ) as {key: $k, value: $h}
      | if .d[$k] then empty end
      | if is_door($k) and (cnt($ks;$k)|not) then empty end
      | {$k, h: ($d+$h)}
    ) as {$k, $h} (.; .d[$k] = $h | .q = .q+[[$k,$h]] | .p[$k] = $pos)
  )
  | . as {$p} | .d | del(.[$pos]) | with_entries(select(is_key(.key))|
      .value = [
        .value,
        (
          [ .key | recurse($p[.] | if . == $pos then empty end ) ]
          | reverse | del( .[] | select( test("[@1-4A-Z]") ) )
        ) # Include keys gathered on the way to target keys
      ]   # Output format { "k": [ dist, [ path_to_key ]] }
    )
;

def to_keys($a;$b;$c;$d;$ks): # To keys wrapper for 4 bots
  { "\($a)": to_keys($a;$ks), "\($b)": to_keys($b;$ks),
    "\($c)": to_keys($c;$ks), "\($d)": to_keys($d;$ks), };

{
  q: [[["1","2","3","4"],[],0]],
  d: {"\([["1","2","3","4"],[]])":0}
} | until (isempty(.q[]) or .i > 1e6; # Do dijikstra search where
  .i += 1 | debug({i}) |              # Nodes are [[p1.p4], keys]
  ( .q | min_by(.[2]) ) as [[$u1,$u2,$u3,$u4],$ks,$d]
  |         .q   =   .q - [[[$u1,$u2,$u3,$u4],$ks,$d]] |
  reduce(
    (
      to_keys($u1;$u2;$u3;$u4;$ks) | to_entries[] | .key as $ux |
      .value | to_entries[] | [$ux, .key, .value[0], .value[1] ]
    ) as [$ux, $nxt, $nd, $nk]
    | select($ks|index([$nxt])|not)      # Filter out keys we have
    | ($ks + [$nxt] + $nk |unique) as $nks # Picks keys on the way
    | ($nd + $d) as $nd                       # Distance to target
    | [
        ([$u1,$u2,$u3,$u4] | (.[] | select(. == $ux)) = $nxt ),
        $nd, $nks          # Make next node by updating moved bot.
      ] as [$nxt, $nd, $nks]
    | select((.d["\([$nxt,$nks])"] // 10000) > $nd )
    | [$nxt, $nd, $nks]
  ) as [$nxt, $nd, $nks] (.;
    .q = .q + [[$nxt, $nks, $nd]] | .d["\([$nxt,$nks])"] = $nd
  )
)

# Output minimum distance for max of keys
| .d | to_entries | map(.key |= fromjson)
| max_by((.key[1] | length), -.value)
| .value
