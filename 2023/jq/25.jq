#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Get adjacency graph
reduce (
  inputs | [ scan("[a-z]{3}") ]
) as $edge ({};
  $edge[0] as $parent |
  reduce $edge[1:][] as $child (.;
    .[$parent][$child] = true |
    .[$child][$parent] = true
  )
) | . as $graph |

# BFS to get path between nodes
# And check connectivity
def bfs($graph; $s; $t):
  {
    seen: { $s: true },
    search: [ $s ],
    $graph
  } |
  until (isempty(.search[]) or .seen[$t];
    .search[0] as $u | .search |= .[1:] |
    reduce (.graph[$u] | keys[]) as $child (.;
      if (.seen[$child]|not) then
        .search += [$child] |
        .seen[$child] = $u
      end
    )
  )
;

# Get shortest path between two nodes
def get_path($source; $sink):
  bfs($graph;$source;$sink) | .seen as $seen |
  last([$sink] | recurse(
    $seen[.[-1]] as $source |
    if $source == true then
      empty
    else
      . + [ $source ]
    end
  )) | [ range(length-1) as $i | .[$i:$i+2] ]
;

# Get total graph nodes
( $graph | keys ) as $keys |

# Get "random" pairs of nodes
def random_pairs:
  [ # Get with `cat /dev/urandom | od -And -t u2 | head | jq -s`
    63145,18516,045726,23653,02482,57010,52364,19220,1537,41190,
    53948,60831,11399,38752,53034,15078,29378,34588,16602,11950,
    9094,17523,10064,015948,20508,54725,02797,40737,51667,35015,
    14130,32445,7639,61751,53915,011938,49766,55970,24788,62852,
    7333,013792,50287,59923,04390,45488,1306,028947,50207,45447,
    17014,27215,36611,20396,58332,31759,14098,33776,61574,16349,
    51466,56572,020624,3211,2641,16758,046111,51056,65041,22203,
    19998,06818,32969,010264,47388,08660,4343,36154,28058,30065
    # Norming to keys length
    | . / 65535 | . * ($keys|length)
  ] as $rand |
  [ # Picking random pairs
    range(0;$rand|length;2) as $i
    | $rand[$i:$i+2]
    | [$keys[.[0]],$keys[.[1]]]
  ]
;

# Picking random pairs, if the two groups are
# roughly of the same size, there should be a
# ~50% chance that one of the three cuts is
# along the path
# Picking the most common edge among a
# collection of paths between two nodes
[ random_pairs[] | get_path(.[0];.[1])[] | sort ]
| group_by(.)
| sort_by(-length)
| .[0:3]
| map(.[0]) as $three_cuts |

# Snip snip
reduce $three_cuts[] as [$a,$b] ($graph;
  debug({snipping:[$a,$b]}) |
  del(.[$a][$b]) |
  del(.[$b][$a])
) | . as $graph |

(bfs($graph;$keys[0];"x").seen | keys | length) as $cut_size |

if $cut_size == ($keys|length) then
  "The three cuts did not disconnect the graph, try new random set of pairs"
else
  # Output the product of the sizes of the two new group
  $cut_size * (($keys|length) - $cut_size)
end