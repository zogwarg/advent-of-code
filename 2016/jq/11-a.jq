#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ # Parse inputs as list of floors with items: [[["pol","m"],["pol","g"]], ...]
  inputs
  | .[index("contains")+9:-1]
  | split(", and |, | and ";"")
  | map(scan(" (.{3})\\w+-compatible (m)"), scan(" (.{3})\\w+ (g)en"))
]

# Keep number of floors
| length as $floor_num

# Convert to symmetric state, of item pairs and floor loccation
# Eg: [[0, 0], [0,0], [0,0], [0,1], [0, 1]] with pair=["g","m"]
| to_entries | map(.key as $k | .value[] | [$k, .])
| group_by( .[1][0] )
| map( sort_by(.[1][1]) | [ .[][0] ])
| sort |

# Is input floors state valid ?
def valid_state:
  . as $i | all(.[]; .[1] as $m | .[1] == .[0] or all($i[][0]; . != $m))
;

# Produce all possible next states from current state
def next:
  def next($from; $to): ( .d + 1 ) as $d |
    .i | . as $items
       | to_entries
       # Select all items pairs, with at least one item on current floor
       | map(select(.value | contains([$from])))
       # For symmetry, group by item-pair values
       | group_by(.value) | map({k: [.[].key],v:.[0].value})
       # Take groups of two-matching pairs
       | combinations(2) as [ {k:[$i,$ii],v:$iv}, {k:[$j,$jj],v:$jv} ]
       | select($i <= $j) |

       # Generate all valid moves, overkill elif, sort next state for symmetry
       if $i == $j and $ii and $iv[1] == $from and $iv[0] != $from then
         ($items | .[$i,$ii][1] = $to | select(valid_state) | sort ),
         ($items | .[$i][1]     = $to | select(valid_state) | sort )
       elif $i == $j and $ii and $iv[0] == $from and $iv[1] != $from  then
         ($items | .[$i,$ii][0] = $to | select(valid_state) | sort ),
         ($items | .[$i][0]     = $to | select(valid_state) | sort )
       elif $i == $j and $ii and $iv[0] == $from and $iv[1] == $from  then
         ($items | .[$i,$ii][0] = $to | select(valid_state) | sort ),
         ($items | .[$i][0]     = $to | select(valid_state) | sort ),
         ($items | .[$i,$ii][1] = $to | select(valid_state) | sort ),
         ($items | .[$i][1]     = $to | select(valid_state) | sort ),
         ($items | .[$i][0,1]   = $to | select(valid_state) | sort )
       elif $i == $j and ($ii | not) and $iv[1] == $from and $iv[0] != $from then
         ($items | .[$i][1]     = $to | select(valid_state) | sort )
       elif $i == $j and ($ii | not) and $iv[0] == $from and $iv[1] != $from then
         ($items | .[$i][0]     = $to | select(valid_state) | sort )
       elif $i == $j and ($ii | not) and $iv[0] == $from and $iv[1] == $from then
         ($items | .[$i][0]     = $to | select(valid_state) | sort ),
         ($items | .[$i][1]     = $to | select(valid_state) | sort ),
         ($items | .[$i][0,1]   = $to | select(valid_state) | sort )
       elif $i != $j and $iv[0] == $from and $jv[0] == $from then
         ($items | .[$i,$j][0]  = $to | select(valid_state) | sort )
       elif $i != $j and $iv[1] == $from and $jv[1] == $from then
         ($items | .[$i,$j][1]  = $to | select(valid_state) | sort )
       else
         "Unexpected state" | halt_error
       end

       | {i: ., e: $to, $d}
  ;
  if .e == 0 then
    next(0;1)
  elif .e == 1 then
    next(1;2), next(1;0)
  elif .e == 2 then
    next(2;3), next(2;1)
  elif .e == 3 then
    next(3;2)
  end
;

# Hash for already sorted state.
def hash:
  "\(.e)-" + ( .i | map(join(""))| join(""))
;

{ # BFS
  search: [{
    i: .,
    e: 0,
    d: 0
  }],
  hash: {}
} | until (isempty(.search[]);
  reduce .search[] as $s(.search = [];
    # Store first reached depth for each state
    .hash[$s|hash] = $s.d |

    # Add to search only, if generated move was never seen
    .search += [
      ( $s | next ) as $n | select(.hash[$n|hash] | not) | $n
    ]
  ) |
  # Prune duplicates
  .search |= unique
)

# Output depth for highest hash state
# (all items on final floor)
| .hash[.hash|keys[-1]]