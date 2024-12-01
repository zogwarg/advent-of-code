#!/usr/bin/env jq -n -R -f

#                 Get target area coordinates                 #
[ inputs | [scan("-?\\d+")|tonumber] ] as [[$x1,$x2,$y1,$y2]] |

#        Lower range of vx1 must be       #
#        vx1^2 + vx1 - (2*x1) >= 0        #
def vx1: (-1/2) + (1+8*$x1|sqrt/2) | floor;

# vx can't be 0 at target otherwise there would be no max altitude #
#          Supposing a minimum vx speed of 2 above y=0,            #
#         The probe would cross y=0 at a min of 2*vy1*2            #
#         Overshooting at y=0, means overshooting at y<0           #
#             This gives an upper bound vy1 <= x2/4                #
                                    def vy1:  $x2/4|floor          ;

def hit(p):                            #    Our collision check    #
  p[0] >= $x1 and p[0] <= $x2 and      #                           #
  p[1] >= $y1 and p[1] <= $y2;         #                           #
def out(p): p[0] > $x2 or p[1] < $y1;  #  Our out of bounds check  #

first(
  {
    v: (
      range(vy1;$y1-1; -1) as $vy | # dy: High -> Overshoot
      range(vx1;$x2+1)     as $vx | # dx:  Low -> Overshoot
      [$vx,$vy]
    ),
    p: [0,0], y: 0,
  } |
  first(
    recurse(
      .p = ([.p,.v]|transpose|map(add))
      | .y = ([.y, .p[1]] | max) | .v[1] -= 1
      | if .v[0] != 0 then .v[0] = .v[0] - copysign(1;.v[0]) end
    ) | select(hit(.p) or out(.p))
  )   | select(hit(.p))
).y   # First to hit will have highest dy, and therefore highest y.
