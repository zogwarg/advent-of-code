#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / "" ] | [.,.[0]|length] as [$H,$W] |

#----- In bound selectors -----#
def x: select(. >= 0 and . < $W);
def y: select(. >= 0 and . < $H);

reduce (
  [
    to_entries[] | .key as $y | .value |
    to_entries[] | .key as $x | .value |
    [ [$x,$y],. ]  | select(last!=".")
  ] | group_by(last)[] # Every antenna pair #
    | combinations(2)  | select(first < last)
) as [[[$ax,$ay]],[[$bx,$by]]] ({};
  # Assign anti-nodes #
  .[ (1,-2) as $i | "\(
    [($ax+$i*($ax-$bx)|x), ($ay+$i*($ay-$by)|y)] | select(length==2)
  )"] = true
) | length
