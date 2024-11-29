#!/usr/bin/env jq -n -f

[ inputs ] as [$card_pub, $door_pub] | 20201227 as $M |

def prt_i($i): if $i % 10000 == 0 then debug({$i}) end;

{p: 1, e: 1, i: 0} |

until (
  .p == $card_pub;       .i += 1 | prt_i(.i) |
  .p = .p * 7 % $M | .e = .e * $door_pub % $M
)

| .e # The shared card <-> door encryption key.
