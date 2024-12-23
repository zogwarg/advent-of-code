#!/usr/bin/env jq -n -rR -f

reduce (
  inputs / "-" #         Build connections dictionary         #
) as [$a,$b] ({}; .[$a] += [$b] | .[$b] += [$a]) | . as $conn |

def bron_kerbosch1($R; $P; $X; $cliques):
  if ($P|length) == 0 and ($X|length) == 0 then
    if ($R|length) > 2 then
      {cliques: ($cliques + [$R|sort])}
    end
  else
    reduce $P[] as $v ({$R,$P,$X,$cliques};
      .cliques = bron_kerbosch1(
        .R - [$v] + [$v]     ; # R ∪ {v}
        .P - (.P - $conn[$v]); # P ∩ neighbours(v)
        .X - (.X - $conn[$v]); # X ∩ neighbours(v)
           .cliques
      )    .cliques    |
      .P = (.P - [$v]) |       # P ∖ {v}
      .X = (.X - [$v] + [$v])  # X ∪ {v}
    )
  end
;

bron_kerbosch1([];$conn|keys;[];[]).cliques
| max_by(length) | join(",")
