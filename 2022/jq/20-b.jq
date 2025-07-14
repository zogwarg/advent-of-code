#!/bin/sh
# \
exec jq -n -f "$0" "$@"

[ inputs * 811589153 ] | length as $L | with_entries(
  .value = {
    v: .value, k:(.key|tostring),
    p: (.key - 1 | . + $L | . % $L | tostring),
    n: (.key + 1 | . + $L | . % $L | tostring)
  }
  | .key = (.key|tostring)
)
| reduce range(10) as $_ (.;
  reduce keys_unsorted[] as $k (.;
    if ($k|tonumber%100==0) then debug({$_,$k}) end
    | .c = .[$k] | .c as {$v,$n,$p}
    | ( $L - 1 + ( $v % ( $L - 1 ) ) ) % ( $L - 1 ) as $v |
    if $v > 0 then
      reduce range($v) as $_ (.;
        .c = .[.c.n]
      )
      | .c as {v:$v1,p:$p1,n:$n1,k:$k1}
      | .[$p].n = $n  | .[$n].p = $p
      | .[$k].p = $k1 | .[$k].n = $n1 | ( .[$k1].n , .[$n1].p ) = $k
    end
    | del(.c)
  )
)
| [ .[] | select(.v == 0) | .k ] as [$z] | . as $s
| [ $z | recurse($s[.].n | select($s[.].v != 0) ) | $s[.].v ]
| [ .[ (1000,2000,3000) % length ] ] | debug | add
