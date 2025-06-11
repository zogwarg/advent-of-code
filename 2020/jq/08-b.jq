#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / " " | .[1] |= tonumber ] as $prog |

[
  range($prog|length) | . as $i |
  if $prog[$i][0] == "acc" then
    # If "acc" no new candidates
    empty
  else
    # Otherwise two new candidate programs
    $prog[0:$i] + ("nop", "jmp" | [[.,$prog[$i][1]]] ) + $prog[$i+1:]
  end
  | . as $v | # Execute each new candidate "v"
  {i: 0, acc: 0, s: []} | until (.i as $i | ($v[$i] | not) or (.s | contains([$i]))  ;
    .i as $i |
    if $v[$i][0] == "acc" then
      .acc += $v[$i][1] | .i += 1
    elif $v[$i][0] == "jmp" then
      .i += $v[$i][1]
    else
      .i += 1
    end | .s += [$i]
  )
]

# Output acc of completed program
| max_by(.i).acc
