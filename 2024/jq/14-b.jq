#!/usr/bin/env jq -n -R -f

#     Board size     # Our list of robots positions and speed #
[101,103] as [$W,$H] | [ inputs | [scan("-?\\d+")|tonumber] ] |

#     Making the assumption that the easter egg occurs when   #
#           When the quandrant product is minimized           #
def sig:
  reduce .[] as [$x,$y] ([];
    if $x < ($W/2|floor) and $y < ($H/2|floor) then
      .[0] += 1
    elif $x < ($W/2|floor) and $y > ($H/2|floor) then
      .[1] += 1
    elif $x > ($W/2|floor) and $y < ($H/2|floor) then
      .[2] += 1
    elif $x > ($W/2|floor) and $y > ($H/2|floor) then
      .[3] += 1
    end
  ) | .[0] * .[1] * .[2] * .[3];

#           Only checking for up to W * H seconds             #
#   There might be more clever things to do, to first check   #
#       vertical and horizontal alignement separately         #
reduce range($W*$H) as $s ({ b: ., bmin: ., min: sig, smin: 0};
  .b |= (map(.[2:4] as $v | .[0:2] |= (
    [.,[$W,$H],$v] | transpose | map(add)
    | .[0] %= $W | .[1] %= $H
  )))
  | (.b|sig) as $sig |
  if $sig < .min then
    .min = $sig | .bmin = .b | .smin = $s
  end | debug($s)
)

| debug(
  #    Contrary to original hypothesis that the easter egg    #
  #  happens in one of the quandrants, it is mostly centered  #
  # It is slightly up of center, with a trunk in the middle.  #
  #-----------------------------------------------------------#
  #     For most steps, the vertical distribution should be   #
  #   half-half noise, so slightly up minimizes the product.  #
  #-----------------------------------------------------------#
  # The easter-egg step is half-half like on most noise steps.#
  #   But the robots in the middle trunk don't contribute to  #
  #     the product thus minimizing the quadrant product.     #
  reduce .bmin[] as [$x,$y] ([range($H)| [range($W)| " "]];
    .[$y][$x] = "█"
  ) | .[] | add
)

| .smin + 1 # Our easter egg step
