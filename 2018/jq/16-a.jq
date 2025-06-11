#!/bin/sh
# \
exec jq -n -csR -f "$0" "$@"

# Parse inputs
inputs / "\n\n\n" | .[0] = [ .[0] / "\n\n" | .[] | [ scan("\\d+")|tonumber ] | {
  bf: .[0:4],
  af: .[8:12],
  op: .[4:8]
}]
| .[1] = [ .[1] / "\n" | .[] | [ scan("\\d+")|tonumber ] | select(. != []) ]
| . as [ $spl, $pgrm ] |

def do($op; $r; $i):
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
  def sym: ((.. | nulls) = 0) | sort;
  $i as [$_, $a, $b, $c] |
  if   $op == "addr" then $r | .[$c] = .[$a] + .[$b]
  elif $op == "addi" then $r | .[$c] = .[$a] +   $b
  elif $op == "mulr" then $r | .[$c] = .[$a] * .[$b]
  elif $op == "muli" then $r | .[$c] = .[$a] *   $b
  elif $op == "banr" then $r | .[$c] = (
    [ .[$a], .[$b] | to_bits ]
    | [ {"[1,1]": 1, "[0,1]": 0, "[0,0]": 0}["\(transpose[] | sym)"]]
    | from_bits
  )
  elif $op == "bani" then $r | .[$c] = (
    [ .[$a], $b | to_bits ]
    | [ {"[1,1]": 1, "[0,1]": 0, "[0,0]": 0}["\(transpose[] | sym)"]]
    | from_bits
  )
  elif $op == "borr" then $r | .[$c] = (
    [ .[$a], .[$b] | to_bits ]
    | [ {"[1,1]": 1, "[0,1]": 1, "[0,0]": 0}["\(transpose[] | sym)"] // 0 ]
    | from_bits
  )
  elif $op == "bori" then $r | .[$c] = (
    [ .[$a], $b | to_bits ]
    | [ {"[1,1]": 1, "[0,1]": 1, "[0,0]": 0}["\(transpose[] | sym)"] // 0 ]
    | from_bits
  )
  elif $op == "setr" then $r | .[$c] = .[$a]
  elif $op == "seti" then $r | .[$c] =   $a
  elif $op == "gtir" then $r | .[$c] = if   $a  >  .[$b] then 1 else 0 end
  elif $op == "gtri" then $r | .[$c] = if .[$a] >    $b  then 1 else 0 end
  elif $op == "gtrr" then $r | .[$c] = if .[$a] >  .[$b] then 1 else 0 end
  elif $op == "eqir" then $r | .[$c] = if   $a  == .[$b] then 1 else 0 end
  elif $op == "eqri" then $r | .[$c] = if .[$a] ==   $b  then 1 else 0 end
  elif $op == "eqrr" then $r | .[$c] = if .[$a] == .[$b] then 1 else 0 end
  end
;

[
  $spl[] | [
    do(
      "addr", "banr", "mulr", "borr", "setr",
      "addi", "bani", "muli", "bori", "seti",
      "gtir", "gtri", "gtrr",
      "eqir", "eqri", "eqrr";
      .bf; .op
    ) == .af | select(.)
  ] | select(length >= 3)
  # Print number of quite ambiguous samples
] | length
