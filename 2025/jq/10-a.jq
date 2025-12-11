#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / " " | map([ scan("[.#]|\\d+") | tonumber? // if . == "." then 0 else 1 end ]) ] |

( [ .[] | length - 2 ] | max ) as $M |

def to_bits:
  [ range($M) | 0 ] as $pad |
  if . == 0 then [0] else { a: ., b: [] } | until (.a == 0;
      .a /= 2 |
      if .a == (.a|floor) then .b += [0]
                          else .b += [1] end | .a |= floor
  ) | .b end | . + $pad | .[0:$M]
;

[ range(pow(2;$M)) as $i |
  $i | to_bits
] as $nums |

(
  reduce range($M+1) as $i ([];
    . + [ $nums[] | select(add == $i) ]
  )
) as $tests |

[
.[] |
  first(
    .[0] as $lights | .[1:-1] as $buttons |
    debug({$lights,$buttons}) |
    $tests[] as $test |
    reduce ($buttons|to_entries[]) as {key: $i, value: $idx} (
      [];
      .[if $test[$i] == 1 then $idx[] else empty end ] += 1
    ) |
    select(([. , $lights ] | transpose | map(add % 2) | unique) == [0]) |
    $test | add
  )
] | add