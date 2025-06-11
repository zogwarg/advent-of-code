#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

# Get padded grid
[ inputs / "" | ["."] + . + ["."] ] |
[ .+[0,0],.[0]| length ] as [$H,$W] |
[[ range($W) | "." ]] + . +
[[ range($W) | "." ]] |

{s:., h: {}, x: null, n: 0} |

until (
  .x or .n > 10000;
  (.s|map(add)|add) as $k |
  if .h[$k] then
    .x = .h[$k]
  else
    .h[$k] = .n | .n += 1 | debug({n}) |
    reduce (
      range(1;$H-1) as $i | range(1;$W-1) as $j |
      {
        $i,$j,
        s: .s[$i][$j],
        m: (
          [.s[range($i-1;$i+2)][range($j-1;$j+2)]]|del(.[4])|sort|add
        )
      }
      | .s = (
          if .s == "." and .m[-3:]           == "|||" then "|"
        elif .s == "|" and .m[0:3]           == "###" then "#"
        elif .s == "#" and .m[0:1] + .m[-1:] == "#|"  then "#"
        elif .s == "#"                                then "."
        else .s end
      )
      | {i,j,s}
    ) as {$i,$j,$s} (.;
      .s[$i][$j] = $s
    )
  end
) |

# Display: .s[1:-1][] | add[1:-1]

# With board state starting to loop at index x, with period (n - x):
# -----------------------------------------------------------------
#              Board(x + i        ) = Board(x +         i % (n - x))
# Board(1e9) = Board(x + (1e9 - x)) = Board(x + (1e9 - x) % (n - x))
debug({x, n}) | (.x + (1e9 - .x) % (.n - .x) | debug({z:.})) as $z |

# Get final board at 1e9
(.h | to_entries[] | select(.value == $z).key ) |
[ # Compute n_yards x n_trees
  ([. | scan("#")]  | length),
  ([. | scan("\\|")]| length)
] | .[0] * .[1]
