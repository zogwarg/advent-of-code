#!/usr/bin/env jq -n -sR -f

[ inputs | scan("\\d+") | (10+tonumber-1) % 10 ] as [$_,$p1,$_,$p2] |

{ p: 0, pos:[$p1,$p2], s: [0,0], i: 1 } |

until (
  # Until any player has score >= 1000 #
  any(.s[];. >= 1000);
  # Throw our very "random" dice #
  ([range(.i;.i+3)] | add) as $throw | .i = .i + 3 |
  # Update position and score #
  .pos[.p] = ( .pos[.p] + $throw ) % 10 |
    .s[.p] =     .s[.p] + .pos[.p] + 1  |
  # Switch players #
  .p = [1,0][.p]
)

# Losing score x number of dice throws #
| first(.s[]|select(.< 1000)) * (.i - 1)
