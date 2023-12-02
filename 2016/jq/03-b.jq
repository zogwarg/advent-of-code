#!/usr/bin/env jq -n -f
reduce (
  # Re-arrange and produce new stream,
  # And re-use part 1 code
  [ inputs ] | . as $in | length as $l
  | range(3) as $i
  | [ $in[range($l) | select(. % 3 == $i )] ][]
) as $i ({s:[],t:0};
  if .s | length == 2 then
    ( [.s[], $i] | sort ) as $t |
    if $t[0:2] | add > $t[2] then
      .t += 1
    else
      .
    end
    | .s = []
  else
    .s += [$i]
  end
)

# Output total valid triangles
| .t