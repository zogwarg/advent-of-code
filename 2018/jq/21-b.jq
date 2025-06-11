#!/bin/sh
# \
exec jq -n -cR -f "$0" "$@"

[ inputs ] |

# Set instruction pointer register
(.[0]/" "|.[1]|tonumber) as $ipr |

# Load program and initialize registers
{
  pg: [ .[1:][] / " " | .[1:] |= map(tonumber) ],
  rg: [    range(6)   |         0              ],
  i: 0
} |

if any(.pg[][3]; . == 0) then "Non static R0" | halt_error end |

( # Index of equality on exit
  .pg | map(
    map(tostring)
    |join(" ")
    |test("^eqrr (0 [1-5]|[1-5] 0) [1-5]$")
  ) | indices(true)
) as [$exit_idx] |

# Get that R0 must be equal to at exit_idx, to cmplt prgmr
first(.pg[$exit_idx][1,2]|select(.!=0)) as $exit_cmp_reg |

# Quite slow with JQ taking around 6h
last(label $out | limit(50000;foreach(
  while (.pg[.rg[$ipr]];
    def to_bits:
      if . == 0 then [0] else
        {
          a: .,
          b: []
        } | until (.a == 0;
          .a /= 2 |
          if .a == (.a|floor) then
            .b += [0]
          else
            .b += [1] | .a |= floor
          end
        ) | .b
      end
    ;
    def from_bits:
      {
        a: 0,
        b: .,
        l: length,
        i: 0
      } | until (.i == .l;
        .a += .b[.i] * pow(2;.i) | .i += 1
      ) | .a
    ;
    def sym: ((.. | nulls) = 0) | sort; .i += 1 |
    .pg[.rg[$ipr]] as [$op,$a,$b,$c] |
      if $op == "seti" then .rg[$c] = $a
    elif $op == "setr" then .rg[$c] = .rg[$a]
    elif $op == "addi" then .rg[$c] = .rg[$a] + $b
    elif $op == "addr" then .rg[$c] = .rg[$a] + .rg[$b]
    elif $op == "muli" then .rg[$c] = .rg[$a] * $b
    elif $op == "mulr" then .rg[$c] = .rg[$a] * .rg[$b]
    elif $op == "gtir" then .rg[$c] = if     $a  >  .rg[$b] then 1 else 0 end
    elif $op == "gtri" then .rg[$c] = if .rg[$a] >      $b  then 1 else 0 end
    elif $op == "gtrr" then .rg[$c] = if .rg[$a] >  .rg[$b] then 1 else 0 end
    elif $op == "eqir" then .rg[$c] = if     $a  == .rg[$b] then 1 else 0 end
    elif $op == "eqri" then .rg[$c] = if .rg[$a] ==     $b  then 1 else 0 end
    elif $op == "eqrr" then .rg[$c] = if .rg[$a] == .rg[$b] then 1 else 0 end
    elif $op == "banr" then .rf[$c] = (
      [ .rg[$a], .rg[$b] | to_bits ]
      | [ {"[1,1]": 1, "[0,1]": 0, "[0,0]": 0}["\(transpose[] | sym)"]]
      | from_bits
    )
    elif $op == "bani" then .rg[$c] = (
      [ .rg[$a], $b | to_bits ]
      | [ {"[1,1]": 1, "[0,1]": 0, "[0,0]": 0}["\(transpose[] | sym)"]]
      | from_bits
    )
    elif $op == "borr" then .rg[$c] = (
      [ .rg[$a], .rg[$b] | to_bits ]
      | [ {"[1,1]": 1, "[0,1]": 1, "[0,0]": 0}["\(transpose[] | sym)"] // 0 ]
      | from_bits
    )
    elif $op == "bori" then .rg[$c] = (
      [ .rg[$a], $b | to_bits ]
      | [ {"[1,1]": 1, "[0,1]": 1, "[0,0]": 0}["\(transpose[] | sym)"] // 0 ]
      | from_bits
    )
    else
      "Unexpected: \($op)" | halt_error
    end | .rg[$ipr] += 1
  ) | select(.rg[$ipr] == $exit_idx ).rg[$exit_cmp_reg]
) as $i (
  {l:0}; # Exit when value at exit_cmp_reg starts looping
  if .["\($i)"] then break $out else .["\($i)"] = true | .l += 1 end;
  debug({l}) | $i
)))
