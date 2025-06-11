#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

def to_int:
  ( . | length ) as $n | reduce (
    . / "" | [[ reverse[] | tonumber ],[range($n)]] | transpose[]
  ) as [$d,$p] (0; . + $d * pow(2; $p))
;

# Get columns and num lines
[ [ inputs / "" ] | transpose[] ] as $cols | ( $cols[0] | length ) as $n_lines

# Filter indices, get ox binary and convert to int
| .ox = ([$cols[][reduce ($cols[]) as $col ({i:[range($n_lines)]};
  if .i | length == 1 then . else
    .i = .i - ( [ $col[.i[]] ] | group_by(.) | map(length) as [$z,$o] | if $o >= $z then $col | indices("0") else $col | indices("1") end )
  end
)|.i[0]]] | join("") | to_int)

# Filter indices, get co2 binary and convert to int
| .co2 = ([$cols[][reduce ($cols[]) as $col ({i:[range($n_lines)]};
  if .i | length == 1 then . else
    .i = .i - ( [ $col[.i[]] ] | group_by(.) | map(length) as [$z,$o] | if $z > $o then $col | indices("0") else $col | indices("1") end )
  end
)|.i[0]]] | join("") | to_int)

# Output ox * co2
| .ox * .co2
