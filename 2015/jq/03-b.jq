#!/usr/bin/env jq -n -R -f
reduce (inputs / "" | .[] ) as $move ({g:{"0,0":1},s:[0,0],r:[0,0], c: "s"};
  # ^>v<
  if $move == "^" then
    .[.c][1] += 1
  elif $move == ">" then
    .[.c][0] += 1
  elif $move == "v" then
    .[.c][1] -= 1
  else
    .[.c][0] -= 1
  end
  | .g[.[.c]|join(",")] += 1
  | if .c == "s" then .c = "r" else .c = "s" end
)

# Count locations given at least one gift
| .g | length
