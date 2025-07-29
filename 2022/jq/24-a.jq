#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs[1:-1] / "" ][1:-1] | [ ., .[0] | length ] as [$H,$W] |

reduce (
  to_entries[] | .key as $y | .value | to_entries[] | .key as $x | .value |
  select(test("[<>^v]")) | {$x,$y,v:.}
) as {$x,$y,$v} (
  {};
  if $v|test("[<>]") then .y[$y] else .x[$x] end += [{ $x, $y, $v }]
) |

def collide($x;$y;$m;$b):
    if $b.v == ">" then $y == $b.y and ($x - $b.x - $m) % $W == 0
  elif $b.v == "<" then $y == $b.y and ($x - $b.x + $m) % $W == 0
  elif $b.v == "v" then $x == $b.x and ($y - $b.y - $m) % $H == 0
  elif $b.v == "^" then $x == $b.x and ($y - $b.y + $m) % $H == 0
  else "Unexpected!" | halt_error end
;

. as $blizzards |

last(
  label $out | foreach range(1e9) as $_ (
    { heap: [ {m: 1, x: 0, y: 0, h: "v"} ] };

    if $_ % 100 == 0 then debug({$_,h:(.heap|length)}) end |

    def cost($e): $e.m + ($H-$e.y) + ($W - 1 - $e.x);
    def heap_push($e):
      def   rank($i): $i + 1 | logb;
      def parent($i): rank($i) as $r |
        $i - (pow(2;$r) - 1) | . / 2 | pow(2;$r-1) - 1 + . | floor;

      .heap = .heap + [$e] | .i = (.heap|length-1) | .p = parent(.i) |
      until (
        .i == 0 or cost(.heap[.p]) < cost(.heap[.i]);
        {i,p,cur: .heap[.i]} as {$i,$p,$cur} |
        .i = .p | .heap[$i] = .heap[$p] | .heap[$p] = $cur |
        .p = parent(.i)
      ) | {seen, heap}
    ;

    def heap_pop:
      def rank($i): $i + 1 | logb;
      def child($i): rank($i) as $r |
        $i - (pow(2;$r) - 1) | . * 2 | pow(2;$r+1) - 1 + .;

      if .heap|length > 1 then
          .heap = .heap[-1:] + .heap[1:-1]
        | .i = 0 | .l = child(.i) | .r=.l+1 |
        until (
          ((.heap[.l]|not) or cost(.heap[.i]) < cost(.heap[.l])) and
          ((.heap[.r]|not) or cost(.heap[.i]) < cost(.heap[.r]));
          (
            if   (.heap[.r]|not) or cost(.heap[.l]) < cost(.heap[.r])
            then {i, c: .l, cv: .heap[.l]}
            else {i, c: .r, cv: .heap[.r]}
            end
          ) as {$i, $c, $cv} |
          .heap[$c] = .heap[$i] | .heap[$i] = $cv |
          .i = $c | .l = child(.i) | .r = .l + 1
        )
      else {seen, heap: []} end | {seen, heap}
    ;

    if .target or (.heap|length) == 0 then break $out end |
    .heap[0] as {$m,$x,$y,$h} | heap_pop |

    if $x == ($W - 1) and $y == ($H - 1) then
      .target = { m: $m + 1, path: $h + "v" }
    else
      reduce (
        (
          [$x-1,$y,"\($h)<"], [$x+1,$y,"\($h)>"],
          [$x,$y-1,"\($h)^"], [$x,$y+1,"\($h)v"],
          [$x, $y ,"\($h)w"]
        ) as [$x,$y,$h] | {$x,$y,m:$m+1,$h} | .m as $m
        | select($x >= 0 and $x < $W and $y >= 0 and $y < $H)
        | select(all(
            $blizzards.x[$x], $blizzards.y[$y] | arrays[];
            collide($x;$y;$m;.) == false
          ))
      ) as $e (.;
        if .seen["\($e|{x,y,m})"]|not then
          heap_push($e) | .seen["\($e|{x,y,m})"] = true
        end
      )
    end
  )
) | .target | debug({path}) | .m
