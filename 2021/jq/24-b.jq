#!/usr/bin/env jq -n -rR -f

[
  inputs|scan("^(...) ([^ ]+) ?(.+)?$") | .[1:] |= map(tonumber? // .)
] | [ range(0;length;18) as $i | .[$i:($i+18)] ]

#═════════════════════════ Assertion Block ══════════════════════════#

| if length != 14 or any(.[];
     .[0:4] != [ ["inp","w",null],                      # W = wi
                 ["mul","x", 0  ],                      #
                 ["add","x","z" ],                      #
                 ["mod","x", 26 ]]                      # X = b26u(Z)
  or (.[4] | . !=["div","z", 1  ] and .!=["div","z",26])# noop or Z>>1
  or (.[5][0:2]!=["add","x"     ])                      # X = X + xi
  or .[6:15] != [["eql","x","w" ],                      #
                 ["eql","x", 0  ],                      # X =!= w
                 ["mul","y", 0  ],                      #
                 ["add","y", 25 ],                      #
                 ["mul","y","x" ],                      # Y=1  or Y=26
                 ["add","y", 1  ],                      #  !x  or  x
                 ["mul","z","y" ],                      # noop or Z<<1
                 ["mul","y", 0  ],                      #
                 ["add","y","w" ]]                      #
  or.[15][0:2] !=["add","y"     ]                       # if x:
  or .[16:18] !=[["mul","y","x" ],                      # Z += w + yi
                 ["add","z","y" ]]
  or any(.[5,15][2]; abs > 25) #   xi and yi are in base26 range  #
) or (
  [
            [.[][5][2]],
    [0,.[0:-1][][15][2]],      # !x noop branch should not happen #
            [.[][4][2]]        #        When .[4][2] == 1         #
  ]
  | transpose | map(select(last == 1)|.[0:2]|add > 10)
  | unique != [true]
) or (
  .[0 ][4][2] != 1  or # There are a balanced stack of #
  .[-1][4][2] != 26 or # .[4][2] = 1 and .[4][2] = 26  #
  (map(.[4][2]) | sort) != [(range(7)|1), (range(7)|26)]
) then "Input program does not match expectations!" | halt_error end |

# Corresponds to:
#
# Z(i) { // ith program, xi = .[5][2], yi = .[15][2]
#   if .[4][2] == 26 then shift Z to right in base 26 // Pop
#   if .[4][2] == 26 && (digit_26(z(i-1))+xi == wi) { // wj+yj+xi==wi
#     noop
#   } else {
#     ( shift Z to left in base 26 ) + ( wi + yi )    // Push
#   }
# }

#══════════════════════════ Main Block ══════════════════════════════#

reduce (
  [ map([.[4,5,15][2]]), [range(14)] ] | transpose[]
) as [[$op,$x,$y],$i] ({};
  if $op == 1 then .s = [{v:$y,$i}] + .s else # Push            #
    .s[0] as {v:$y,i:$j} | .s = .s[1:] |      # Pop             #
    if $y+$x < 0 then
      .m[$i] = 1 | .m[$j] = 1 - $y - $x       # Set minimum i,j #
    else                                      # With diff xj+yi #
      .m[$j] = 1 | .m[$i] = 1 + $y + $x
    end
  end
)

# Minimum valid model #
| [.m[]|tostring] | add
