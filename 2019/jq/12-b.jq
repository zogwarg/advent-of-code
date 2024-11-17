#!/usr/bin/env jq -n -R -f

# Gaze upon these fair moons, and see their dances
[ inputs | [[scan("-?\\d+") | tonumber],[0,0,0]]]|

{
  moons_x: map(map(.[0])),
  moons_y: map(map(.[1])),
  moons_z: map(map(.[2]))
} |

def tick_axis($moons_w):
  reduce $moons_w[] as [$mp,$mv] ([];
    . + [[$mp,$mv]] |
    reduce $moons_w[] as [$np,$nv] ( .;
      .[-1][1] |= if $mp>$np then .-1 elif $mp<$np then .+1 end
    ) |
    .[-1][0] = .[-1][0] + .[-1][1]
  )
;

def period_axis($moons_w;$w): # First repeated state is "0"
  {$moons_w, s: "\([$moons_w[][]]|tojson)", i: 0} | until (
    .done or .i > 1000000;
    if .i % 10000 == 0 then debug({i,$w}) end|
    .i += 1 | .moons_w = tick_axis(.moons_w) |
    if "\([.moons_w[][]]|tojson)" == .s then .done = true end
  ) | .i | if  . > 1000000  then "Too high!" | halt_error end
;

def GCD($a; $b): if $b == 0 then $a else GCD($b; $a % $b) end;
def LCM($a; $b): $a / GCD($a;$b) * $b;
def LCM($args):
  if ($args|length) == 2 then LCM($args[0];$args[1])
  else LCM($args[0]; LCM($args[1:])) end
;

LCM([
  period_axis(.moons_x;"x"),
  period_axis(.moons_y;"y"),
  period_axis(.moons_z;"z")
])
