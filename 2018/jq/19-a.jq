#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

[ inputs ] |

# Set instruction pointer register
(.[0]/" "|.[1]|tonumber) as $ipr |

# Load program and initialize registers
{
  pg: [ .[1:][] / " " | .[1:] |= map(tonumber) ],
  rg: [    range(6)   |         0              ]
} |

def replace_sum_factors_routine:
  def detect($n):
    # Test program portion
    (.pg[$n:$n+15]|map(map(tostring)|join(" "))|join("#")) as $pg |

    (
      [ # Being overly thorough with combinations
        ["seti 1 \\d+ a"],
        ["seti 1 \\d+ b"],
        ["mulr a b c","mulr b a c"],
        ["eqrr c x c","eqrr x c x"],
        ["addr c s s","addr s c s"],
        ["addi s 1 s"],
        ["addr a 0 0","addr 0 a 0"],
        ["addi b 1 b"],
        ["gtrr b x c"],
        ["addr c s s","addr s c s"],
        ["seti m \\d+ s"],
        ["addi a 1 a"],
        ["gtrr a x c"],
        ["addr c s s","addr s c s"],
        ["seti n \\d+ s"]
      ]
    ) as $routine |

    first(
      def perms:
        if length == 1 then . else
        .[] as $c | ( . - [$c] | perms) as $arr | [$c, $arr[]]
        end
      ;
      [ range(1;6) | tostring] - [$ipr | tostring]
      | perms | . as [$a, $b, $c, $x]
      | first (
          $routine | (.. | strings) |= (
            gsub(   "c"   ;    $c    ) | gsub("x";    $x  ) |
            gsub("\\ba\\b";    $a    ) | gsub("b";    $b  ) |
            gsub("\\bm\\b"; "\($n+1)") | gsub("n"; "\($n)") |
            gsub("\\bs\\b"; "\($ipr)")
          )
          | combinations | join("#") as $candidate
          | select($pg | test($candidate))
        )
      | [$a, $b, $c, $x, $n | tonumber]
    )
  ;
  [
    first(
      detect(range(.pg| length - 15))
    )
  ] as [[$a,$b,$c,$x,$n]] | if $a | not then
    "Error: Could not detect sum factors routine" | halt_error
  end |
  .pg[$n] = ["rout",$a,$b,$c,$x,($n+14)] |
  .pg[$n+1:$n+15][] = ["noop"]
;

replace_sum_factors_routine |

until (.pg[.rg[$ipr]]|not;
  .pg[.rg[$ipr]] as [$op,$a,$b,$c,$x,$j] |
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
  elif $op == "rout" then
    .rg[$x] as $X |
    # Update registers to final values
    (.rg[$a],.rg[$b]) = $X | .rg[$c] = 1 | .rg[$ipr] = $j |

    # Output .rg[0] to sum of factors of x
    .rg[0] = (
      reduce range(1;$X+1) as $i (0;
        if $X % $i == 0 then . + $i end
      )
    )
  else
    "Unexpected: \($op)" | halt_error
  end | .rg[$ipr] += 1
)

# Final output
| .rg[0]
