#!/usr/bin/env jq -n -R -f

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
  # Assign linear anti-nodes #
  .[ range(-$H;$H) as $i | "\(
    [($ax+$i*($ax-$bx)|x), ($ay+$i*($ay-$by)|y)] | select(length==2)
  )"] = true
) | length
