#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Absurdly slow in JQ
inputs / "" | map(tonumber) as $recipe | ($recipe|length) as $l |

{
  scores: [3,7],
  elf1: 0,
  elf2: 1,
}
|
until (.scores[-$l:] == $recipe or .scores[-$l-1:-1] == $recipe;
  .i += 1 |
  if .i % 1000 == 0 then debug(.i) end |
  .scores = .scores + [
    [0],[1],[2],[3],[4],[5],[6],[7],[8],[9],
    [1,0],[1,1],[1,2],[1,3],[1,4],[1,5],
    [1,6],[1,7],[1,8]
  ][.scores[.elf1] + .scores[.elf2]] |
  .elf1 = (.elf1 + .scores[.elf1] + 1 ) % (.scores|length) |
  .elf2 = (.elf2 + .scores[.elf2] + 1 ) % (.scores|length)
)
|
if .scores[-$l:] == $recipe then
  .scores | length - $l
else
  .scores | length - $l - 1
end
