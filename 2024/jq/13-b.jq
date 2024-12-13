#!/usr/bin/env jq -n -sR -f

[ inputs|rtrimstr("\n")|split("\n\n")[] | [ scan("\\d+")|tonumber ]] |
# Increase distance to target.
map(.[4:6] |= map(. + 1e13)) |

[
  .[] | . as [$ax, $ay, $bx, $by, $X, $Y] |
  #          Equation is not solvable or degenerate           #
  if $ax * $by - $ay * $bx == 0 then "Oups!" | halt_error end |
  [ #   Solve system of equations with determinant  #
    (($X * $by - $Y * $bx) / ($ax * $by - $ay * $bx)),
    (($ax * $Y - $ay * $X) / ($ax * $by - $ay * $bx))
    # Only keep solution in ℕ^2 then compute tokens #
  ] | select(all(.[]; . == trunc)) | .[0] * 3 + .[1]
] | add
