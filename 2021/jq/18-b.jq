#!/bin/sh
# \
exec jq -n -f "$0" "$@"

#                Magnitude of snailfish number                 #
def mag: walk(if type == "array" then 3 * first + 2 * last end);

def action:
  ([
    [      path(..|numbers)      ], # - Path of each number #
    [      (..|numbers > 9)      ], # - Greater than 10?    #
    [ range([..|numbers]|length) ]  # - In order index      #
  ]|transpose) as $p |

  # First exploding elligible pair
  [ first($p[]|select(.[0]|length>4)) ] as [[$ex,$_,$i]] |
  # First splitting elligible number
  [     first($p[]|select(.[1]))      ] as [[$sp,$_,$j]] |

  # Explode #
  if $ex then
    if $i > 0 then
      setpath($p[$i-1][0];getpath($p[$i-1][0])+getpath($p[ $i ][0]))
    end |
    if $i+1 < $p[-1][-1] then
      setpath($p[$i+2][0];getpath($p[$i+2][0])+getpath($p[$i+1][0]))
    end |
    setpath($p[$i][0][:-1]; 0)
  # Or split  #
  elif $sp then
    setpath($p[$j][0]; getpath($p[$j][0]) / 2 | [floor,ceil])
  end
;

def _reduce: {curr: ., prev: null} | until ( #                      #
      .curr == .prev ;                       # Repeat reduce action #
      .prev =  .curr | .curr |= action       #      until done      #
  ) | .curr                                ; #                      #


reduce (
  [ inputs ] | combinations(2) | select(.[0] != .[1]) # Foreach pair
             | _reduce | mag                          # Get magnitude
) as $mag (0; [.,$mag] | debug | max)                 # -> Output max
