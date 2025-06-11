#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

# Build directory tree
reduce ( inputs / "$ " | .[] | select( . != "") | rtrimstr("\n") / "\n") as $line ({pos: [], "/":{}};
  ( $line[0] / " " ) as [ $cmd , $arg ] |
  if $line[0] == "cd /" then
    .pos = ["/"]
  elif $cmd == "cd" then
    if $arg == ".." then
      .pos |= .[:-1]
    else
      .pos += [$arg] |
       getpath(.pos) += {}
    end
  elif $cmd == "ls" then
    getpath(.pos) = (
      (
        $line[1:] | map(. / " " |
          if .[0] == "dir" then {(.[1]):{}} else {(.[1]):(.[0]|tonumber)} end
        ) | add
      ) + getpath(.pos) # Preserve pre-exiting dir paths, with potential info.
    )
  else
    .
  end
) |

[
  # Select all dirs sizes
  .["/"] | .. | objects | [.. | numbers ] | add
]

# Find size of smallest directory to delete
# to have free space >= 30_000_000
| sort
| (( 30000000 + max ) - 70000000 ) as $should_free
| first(.[] | select(. >= $should_free))
