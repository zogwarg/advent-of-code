#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

{
  line: "_"
}

# Read until line break // parse stacks
| until (.line == "";
  .line = input |
  reduce (
    .line | match("\\[.\\]| \\d+ ?";"g") | [(.offset|tostring), .string[1:2]]
  ) as $m ({m,line};
    .m[$m[0]] += [$m[1]]
  )
)
| { stacks: [ .m[] | reverse | {(.[0]): .[1:]} ] | add }

# Move items from stack to stack
| reduce ( inputs | [ match("\\d+"; "g").string ] | .[0] |= tonumber) as [$n, $from, $to] ({stacks};
  ( .stacks[$from] | reverse[0:$n] ) as $move |
  .stacks[$from] |= .[0:0-$n] |
  .stacks[$to] += $move
)

# Output letters at the top of each stack
| .stacks | [ to_entries | sort_by(.key | tonumber)[].value[-1]] | add
