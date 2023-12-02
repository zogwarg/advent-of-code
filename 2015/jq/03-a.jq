#!/usr/bin/env jq -n -R -f
reduce (inputs / "" | .[] ) as $move ({g:{"0,0":1},pos:[0,0]};
  # ^>v<
  if $move == "^" then
    .pos[1] += 1
  elif $move == ">" then
    .pos[0] += 1
  elif $move == "v" then
    .pos[1] -= 1
  else
    .pos[0] -= 1
  end
  | .g[.pos|join(".")] += 1
)

# Count locations given at least one gift
| .g | length
