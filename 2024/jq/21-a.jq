#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

{ "[1,0]": ">", "[-1,0]": "<", "[0,1]": "v", "[0,-1]": "^" } as $key |

{ "[0,0]": "7", "[1,0]": "8", "[2,0]": "9",
  "[0,1]": "4", "[1,1]": "5", "[2,1]": "6",
  "[0,2]": "1", "[1,2]": "2", "[2,2]": "3",
                "[1,3]": "0", "[2,3]": "A"  } as $numpad |

{              "[1,0]": "^", "[2,0]": "A",
 "[0,1]": "<", "[1,1]": "v", "[2,1]": ">"   } as $keypad |

def _r: with_entries({key: .value, value: .key|fromjson});

[$numpad,$keypad|_r] as [$_numpad,$_keypad] |

# BFS search for best path to target #
def pad($curr; $target; $pad; $_pad):
  { q: [[$curr, 0]], s: {"\($curr)": 0}} |
  until (isempty(.q[]); .q[0] as [[$x,$y],$d] | .q = .q[1:] |
    reduce (
      ([1,0],[-1,0],[0,1],[0,-1]) as [$dx,$dy]   |
      [($x+$dx),($y+$dy)] | select($pad["\(.)"]) | [., ($d+1)]
    ) as [$n,$nd] (.;
      if .s["\($n)"] | not then
        .s["\($n)"] = $nd | .q += [[$n,$nd]]
      end
    )
  ) | . as {$s} |
  [ # Extract all best paths, and append "A"  #
    [ $_pad[$target|tostring], [] ] | recurse (
      first as [$x,$y] |
      if $s["\([$x,$y])"] == 0 then empty else
        ([1,0],[-1,0],[0,1],[0,-1]) as [$dx,$dy] |
        [($x-$dx), ($y-$dy)] as [$X,$Y] |
        select($s["\([$X,$Y])"] == $s["\([$x,$y])"] - 1 ) |
        [ [$X,$Y], ([ $key["\([$dx,$dy])"]] + last) ]
      end
    ) | select(first == $curr) | last + ["A"]
  ]
;

#         Wrappers for numpad and keypad BFS searches         #
def numpad($curr;$target): pad($curr;$target;$numpad;$_numpad);
def keypad($curr;$target): pad($curr;$target;$keypad;$_keypad);

#  Min moves for robot from $c to $t at $d  #
def min_moves($curr; $target; $depth; $memo):
  # Internal copy for cyclical calls  #
  def _best_path($path; $depth; $memo):
    if $depth == 1 then { len: $path|length, $memo } else
      reduce (
        [[$_keypad["\("A",$path[:-1][])"]], $path ] | transpose[]
      ) as [$s,$t] ({len: 0, $memo};
        min_moves($s; $t; $depth; .memo) as {$len, $memo}
        | .len += $len | .memo += $memo
      )
    end;

  ( { #   Check if min_moves is already computed    #
      len: $memo["\([$curr, $target,$depth])"], $memo
    } | select(.len)
  ) // (
    #     For all possible paths from current to target      #
    reduce keypad($curr; $target)[] as $p ({len: 1e12, $memo};
      #     Keep the one that minimizes the moves      #
      _best_path($p; $depth - 1; .memo) as {$len, $memo}
      | .memo += $memo
      | if $len < .len then .len = $len end
    ) | .memo["\([$curr, $target,$depth])"] = .len
  )
;

# Get length of best path at depth #
def best_path($path; $depth; $memo):
  if $depth == 1 then { len: $path|length, $memo } else
    reduce (
      [[$_keypad["\("A",$path[:-1][])"]], $path ] | transpose[]
    ) as [$s,$t] ({len: 0, $memo};
      min_moves($s; $t; $depth; .memo) as {$len, $memo}
      | .len += $len | .memo += $memo
    )
  end
;

def numpad_sequences($in):
  [[$_numpad["\("A",$in[:-1][])"]], $in ]
  | transpose
  | map(numpad(.[0];.[1]))
;

reduce inputs as $row ({r:0, memo: {}};
  reduce numpad_sequences($row / "")[] as $paths (.;
    reduce $paths[] as $p (.len = 1e12;
      best_path($p;3;.memo) as {$len, $memo}
      | .memo += $memo
      | if $len < .len then .len = $len end
    ) | .r = .r + (.len * ($row[:-1]|tonumber))
  )
)

| .r # Final output
