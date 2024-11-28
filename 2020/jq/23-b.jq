#!/usr/bin/env jq -n -R -f

reduce (
  inputs / "" | [. , (.[1:] + .[:1]) ] | transpose[] | map(tonumber)
) as [$c,$n] (.;
  # Build array indexed list where, .s[i] = next
  # Because in JQ, editing an array at a large index is not efficient
  # We wrap .s as an array of arrays, of row size 1000
  .c = ( .c // $c ) | .l = $c | .s[$c / 1e3][$c % 1e3] = $n
)

| .s[.l / 1e3][.l % 1e3] = 10 |   #                             #
reduce range(10; 1e6) as $i (.;   # Adding the to_next sequence #
  .s[$i / 1e3][$i % 1e3] = $i + 1 #   For all our extra cups.   #
)                                 #                             #
| .s[1e6 / 1e3][1e6 % 1e3] = .c|  #                             #

# Get next cup in circle
def next($c): .s[$c / 1e3][$c % 1e3];

# Get the cup with the label before this one.
def prev($i): if $i == 1 then 1e6 else $i-1 end;

# Still slow ~3mins but acceptable (vs ~8h)
reduce range(1e7) as $i (.;
  # Get the next three cups ABC
  next(.c) as $a | next($a) as $b | next($b) as $c |

  # Get the first current label ancestor, not in abc
  first(
    prev(.c) | recurse(prev(.))
             | select([.]|inside([$a,$b,$c])|not)
  ) as $t # Target (tgt)

  | .s[.c / 1e3][.c % 1e3] = .s[$c / 1e3][$c % 1e3] # Cur->Next(abc)
  | .s[$c / 1e3][$c % 1e3] = .s[$t / 1e3][$t % 1e3] # ABC->Next(tgt)
  | .s[$t / 1e3][$t % 1e3] = $a                     # Tgt->ABC

  # Update current cup
  | .c = next(.c) | if $i % 10000 == 0 then debug({$i}) end
)

| next(1) * next(next(1))
