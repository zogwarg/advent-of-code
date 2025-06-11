#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

reduce (
  inputs / "-" #         Build connections dictionary         #
) as [$a,$b] ({}; .[$a] += [$b] | .[$b] += [$a]) | . as $conn |


#  Allow Loose max clique check #
if $ARGS.named.loose == true then

# Only works if there is at least one pair in the max clique #
# That only have the clique members in common.               #

[
  #               For pairs of connected nodes                   #
  ( $conn | keys[] ) as $a | $conn[$a][] as $b | select($a < $b) |
  #             Get the list of nodes in common                  #
      [$a,$b] + ($conn[$a] - ($conn[$a]-$conn[$b])) | unique
]

# From largest size find the first where all the nodes in common #
#    are interconnected -> all(connections ⋂ shared == shared)   #
| sort_by(-length)
| first (
  .[] | select( . as $cb |
    [
        $cb[] as $c
      | ( [$c] + $conn[$c] | sort )
      | ( . - ( . - $cb) ) | length
    ] | unique | length == 1
  )
)

else # Do strict max clique check #

# Example of loose failure:
# 0-1 0-2 0-3 0-4 0-5 1-2 1-3 1-4 1-5
# 2-3 2-4 2-5 3-4 3-5 4-5 a-0 a-1 a-2
# a-3 b-2 b-3 b-4 b-5 c-0 c-1 c-4 c-5

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

bron_kerbosch1([];$conn|keys;[];[]).cliques | max_by(length)

end

| join(",") # Output password
