#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

([
     inputs/""  | to_entries
 ] | to_entries | map(
     .key as $y | .value[]
   | .key as $x | .value   | { "\([$x,$y])":[[$x,$y],.] }
)|add) as $grid | #           Get indexed grid          #

($grid[]|select(last=="S")|first) as $S | # Our start position #
($grid[]|select(last=="E")|first) as $E | # Our  end  position #
([$grid|keys[]|fromjson[0]]|max)  as $W | # Our Width          #
([$grid|keys[]|fromjson[0]]|max)  as $H | # Our Height         #

{ q: [[$S, 0]], s: { "\($S)": 0 } } | #    BFS search     #
until (isempty(.q[]); .q[0] as [[$x,$y],$d] | .q = .q[1:] |
  reduce (
    ([0,1],[0,-1],[1,0],[-1,0]) as $step      |
    [[$x,$y],$step] | transpose | map(add)    |
    select($grid["\(.)"] | . and last != "#") | [ . , ($d+1) ]
  ) as [$n, $nd] (.;
    if .s["\($n)"] | not then
      .s["\($n)"] = $nd | .q = .q + [[$n,$nd]]
    end
  )
) | . as {$s} | # Save distance map #

reduce (
  range($W+1)   as $x  | range($H+1)                        as $y  |
  range(-20;21) as $dx | range(-($dx|20-abs); ($dx|21-abs)) as $dy |
  [($x+$dx),($y+$dy)] as [$X,$Y] | # For shortcut of at most 20 ps #
  select($s["\([$x,$y])"] and $s["\([$X,$Y])"]) |
  select(
    $s["\([$X,$Y])"] - $s["\([$x,$y])"] - ([($X-$x),($Y-$y)|abs]|add)
                                 >= 100
  ) #      Count shortcuts that save at least 100 picoseconds      #
) as $i (0; . + 1)
