#!/usr/bin/env jq -n -f
reduce inputs as $i ({s:[],t:0};
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