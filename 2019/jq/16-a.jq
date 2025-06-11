#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

[ inputs / "" | .[] | tonumber ] |

reduce range(100) as $_ (.;
  length as $l | debug($_) | [
    .,
    ( range(1; $l + 1 ) as $i |
      [
        limit($l + 1;  repeat(
          limit($i; repeat(0)),
          limit($i; repeat(1)),
          limit($i; repeat(0)),
          limit($i; repeat(-1))
        ))
      ][1:]
    )
  ]
  | transpose | map(.[0] as $i |.[1:]| map(. * $i))
  | transpose | map( add  % 10 | abs              )
) | map(tostring) | add[0:8]
