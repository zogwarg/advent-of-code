#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce (
  inputs | [ scan("\\d+") | tonumber ]
         | range(3) as $i | .[$i] = .[$i] + ( .5, - .5)
) as $xyz ({}; .["\($xyz)"] += 1 )

| with_entries(select(.value == 1))

#               Get bounding box               #
| ( reduce ( keys[] | fromjson ) as [$x,$y,$z] (
      [ range(3)| (1e12, -1e12) ];
      if $x<.[0] then .[0] = $x end | if $x>.[1] then .[1] = $x end |
      if $y<.[2] then .[2] = $y end | if $y>.[3] then .[3] = $y end |
      if $z<.[4] then .[4] = $z end | if $z>.[5] then .[5] = $z end
    ) | .[range(0;6;2)] -= .5 | .[range(1;6;2)] += .5
  ) as $box
|

{
  walls: . ,
  fill: [ [ $box[range(0;6;2)] ] ],
  touched: { },
  filled: { "\([ $box[range(0;6;2)] ])": true }
} |

#      Filling the box with steam      #
until (isempty(.fill[]);
  .fill[0] as $xyz | .fill = .fill[1:] |
  reduce (
    range(3) as $i | (1,-1) as $s | [
      $xyz | ( .[$i] += (.5,1 | . * $s) )
    ] | select( .[0]
      | all(range(3) as $i | [ .[$i], $box[$i*2]   ]; .[0] >= .[1] )
    and all(range(3) as $i | [ .[$i], $box[$i*2+1] ]; .[0] <= .[1] )
    )
  ) as [$wall,$new] (.;
      if .walls["\($wall)"] then .touched["\($wall)"] += 1
    elif .filled["\($new)"] then . else
      .filled["\($new)"] = true | .fill = .fill + [$new]
    end
  )
)

| .touched | length #    The touched walls are the outside ones.    #
