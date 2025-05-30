#!/usr/bin/env jq -n -R -f

27 as $cut |

#           Parse Directed Graph of valves             #
( [ inputs  | [ scan("[A-Z]{2}|\\d+") | tonumber? // . ]
            | { (.[0]): {rate: (.[1]), to: .[2:]} }
  ]         | add
) as $state |
#           Will later discard all zero rate valves                 #
(    $state | with_entries(select(.key != "AA" and .value.rate == 0))
            | keys
) as $zeros |

reduce (
  #       Foreach non-zero valve       #
  ( $state | keys - $zeros | .[] ) as $k
  # Do BFS search for shortest distance to other valves in $cut mins #
  | { $k, head: [[$k,0]], dist: {} }
  | until (isempty(.head[]); .head[0] as [$h,$v] | .head = .head[1:] |
      reduce (
        $state[$h].to[] | [ ., $v + 1 ] | select(last < $cut)
      ) as [$t, $v] (.;
        if ( .dist[$t] // 1e6 ) >= $v then
          .dist[$t] = $v | .head = .head + [[$t,$v]] | .v = $v
        end
      )
    )
  # Remove dist to R0 valves #
  | del(.dist["AA", $zeros[]])
  # +1 for open  #
  | .dist[] += 1 # Will return compressed graph, without R0 valves #
) as {$k,$dist} ( $state | del(.[$zeros[]])  ;  .[$k].to = $dist ) |

. as $state |

reduce (
  # Lazy exhaustive search #
  [ [["AA"], 0, 1 , 0], [["AA"], 0, 1 , 0] ] | limit(4e7;recurse(
    (.[0][0]|last) as $l |
    ( ($state[$l].to | keys) - .[0][0] - .[1][0] | .[] ) as $n
    | .[0][0] = .[0][0] + [$n]
    | .[0][2] = .[0][2] + $state[$l].to[$n]
    | .[0][3] = .[0][3] + .[0][1] * $state[$l].to[$n]
    | .[0][1] = .[0][1] + $state[$n].rate
    | select(.[0][2] < $cut)
    | if .[0][2] > .[1][2] then reverse end
 )) | map(.[3] + ($cut - .[2]) * .[1]) | add
) as $t ({i:0,t:0};
  if $t > .t then .t = $t end | .i = .i + 1 |
  if .i % 1000 == 0 then debug end
) | .t
