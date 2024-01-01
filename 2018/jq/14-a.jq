#!/usr/bin/env jq -n -r -f

inputs as $recipe |

reduce range($recipe+10) as $_ (
  {
    scores: [3,7],
    elf1: 0,
    elf2: 1
  } ;
  if $_ % 1000 == 0 then debug($_) end |
  .scores = .scores + [
    [0],[1],[2],[3],[4],[5],[6],[7],[8],[9],
    [1,0],[1,1],[1,2],[1,3],[1,4],[1,5],
    [1,6],[1,7],[1,8]
  ][.scores[.elf1] + .scores[.elf2]] |
  .elf1 = (.elf1 + .scores[.elf1] + 1 ) % (.scores|length) |
  .elf2 = (.elf2 + .scores[.elf2] + 1 ) % (.scores|length)
)

| .scores[$recipe:$recipe+10] | join("")
