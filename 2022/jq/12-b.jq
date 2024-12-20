#!/usr/bin/env jq -n -R -f

([
     inputs/""  | to_entries
 ] | to_entries | map(
     .key as $y | .value[]
   | .key as $x | .value   | { "\([$x,$y])": explode[0] }
)|add) as $grid | #           Get indexed grid          #

def get($C): $grid|to_entries[]|select(.value == ($C|explode[0]));
(get("S").key|fromjson) as $S | #     Get our start position     #
(get("E").key|fromjson) as $E | #     Get our  end  position     #
( $grid | .["\($S)"]=97 | .["\($E)"]=122 ) as $grid|# Set Height #

# Step down from best reception spot.
{ q: [[$E, 0]], s: { "\($E)": 0 } } |
last(label $out | foreach range(1e9) as $_ (.;
  if isempty(.q[]) then break $out end |
  .q[0] as [[$x,$y],$d] | .q = .q[1:] |
  reduce (
    ([0,1],[0,-1],[1,0],[-1,0]) as [$dx,$dy] | [($x+$dx),($y+$dy)] |
    select(($grid["\(.)"]//-1) > $grid["\([$x,$y])"] - 2) |
    [., ($d+1)]
  ) as [$n,$nd] (.;
    if .s["\($n)"]|not then
      .s["\($n)"] = $nd | .q += [[$n,$nd]]
    end
  )
)) | .s |= with_entries(.key |= (fromjson[0:2]|tojson)) |

# Get 'a' altitude spot that can be reached first from the top #
[ .s[$grid|to_entries[]|select(.value == 97).key] // 1e9 ] | min
