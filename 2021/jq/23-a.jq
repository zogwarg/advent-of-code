#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

{ A:0, B:1, C:2, D:3 } as $idx   | # Our amphipod types        #
[   1,  10, 100,1000 ] as $costs | # Their cost                #
[   2,   4,   6,   8 ] as $dest  | # Their final destination   #

( [ inputs / "" ] | transpose[1:-1] # Our Board state as array #
  |[.[]|[add|$idx[scan("[A-D]")]]]  # [[], [], [1,2], [], ...] #
) as $board |                       #                          #

( $board | [ to_entries[]              #                       #
  | (.key as $k|$dest|index($k)) as $i #  Desired Board State  #
  | .value | if $i then [ $i, $i ] end #  $dst[$i] == [$i,$i]  #
]) as $final |                         #                       #

{
  #      Dijikstra + Simple Pruning     #
  q: [ [$board,0] ], s: {"\($board)": 0 },
  rem: [0,1,2,3], m: [] # Target Goals  #
} |

until(isempty(.q[]) or .s["\($final)"];

  # Get lowest node from Q  #
  def get: .q | min_by(.[1]);
  def pop(b): .q = .q - [b] ;
  .i += 1 | get as [$b,$d] | pop([$b,$d]) |

  #  Periodic Pruning  #
  if .i % 2000 == 0 then
    debug([.q,.s|length]) | debug({rem,m}) |

    [first( # If a Goal has been reached #
      .rem[] as $i | [ .s
        | keys[] | fromjson
        | select(.[$dest[$i]] == [$i,$i])
      ] | select(length > 100) | $i
    )] as [$d] |

    # Prune Q and visited, from nodes not including reached Goal #
    if $d then .rem -= [$d] | .m += [$d] | .m as $m              #
      | .s |= with_entries( def K: .key | fromjson;              #
          select( K | all($m[] as $i| .[$dest[$i]]==[$i,$i]; .)) #
        )                                                        #
      | .q = ( .s|to_entries | map([(.key|fromjson), .value ]) ) #
    end
  end |

  reduce ( #  For every amphipod on the board, by position  #
    $b | to_entries[] | .key as $i | first(.value[]) | [$i,.]
  ) as [$i, $p] (.;

    # Get cost for amphipod based on distance #
    def cost($dst):  $d +  $dst * $costs[$p]  ;
    # Is target position a goal destination ? #
    def in_dest($t):   [$t] | inside($dest)   ;
    #    Get outer positions towards target   #
    def range_out($t): copysign(1;$t-$i) as $di
             | range($i;$t+$di;$di)
             | select(in_dest(.)|not);

    def move_out($t): # Try moving out to a given target  #
      ($b[$i]|3-length) as $out_i | # ┌─Don't leave goal  #
        if               $i == $dest[$p]         then empty
      elif (first($b[range_out($t)][]) // false) then empty
      else # └─An other amphipod blocks the way to target #
        [
          ($b | .[$t] = [$p] | .[$i] -= [$p]),# New board #
                cost($t - $i | abs + $out_i)  # New cost  #
        ]
      end;

    def move_in: $dest[$p] as $t | #  Try moving to goal  #
      if ( $b[$t] + [$p] | unique | length != 1) then empty
      else ($b[$t]|2-length) as $in |
        [
          ($b | .[$t] += [$p] | .[$i] = []), # New Board  #
                 cost($t - $i | abs + $in)   # New cost   #
        ]
      end;

    reduce( #   For all valid moves, in this given board state    #
      if in_dest($i) then move_out(0,1,3,5,7,9,10) else move_in end
    ) as [$b, $d] (.; #   Update visited, if new cost is lower    #
      if $d<(.s["\($b)"]//1e9) then .s["\($b)"]=$d|.q+=[[$b,$d]]end
    )
  )
)

| .s["\($final)"] # Our Final cost
