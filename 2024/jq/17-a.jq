#!/usr/bin/env jq -n -rR -f

[ inputs | scan("\\d+") | tonumber ] | .[3:] |= [.]
| . as [$A,$B,$C,$pgrm] |

{ p: 0, $A,$B,$C } | until ($pgrm[.p] == null;
  #─────────── Big-endian to_bits and from_bits ────────────#
  def to_bits:
    if . == 0 then [0] else { a: ., b: [] } | until (.a == 0;
        .a /= 2 |
        if .a == (.a|floor) then .b += [0]
                            else .b += [1] end | .a |= floor
    ) | .b end;
  def from_bits:
    { a: 0, b: ., l: length, i: 0 } | until (.i == .l;
      .a += .b[.i] * pow(2;.i) | .i += 1
    ) | .a;
  #──────────── Big-endian xor returns integer ─────────────#
  def xor(a;b): [a, b] | transpose | map(add%2) | from_bits ;

  $pgrm[.p:.p+2] as [$op, $x]       | # Op & literal operand
  [0,1,2,3,.A,.B,.C,null][$x] as $y | # Op &  combo  operand

    if $op == 0 then .A = (.A / pow(2;$y) | trunc)   # A = A SHIFT cmb
  elif $op == 1 then .B = xor(.B|to_bits;$x|to_bits) # B = B X Literal
  elif $op == 2 then .B = ($y % 8)                   # B store cmb mod
  elif $op == 3
   and .A != 0  then .p = ($x - 2)                   # JMP if A nz
  elif $op == 4 then .B = xor(.B|to_bits;.C|to_bits) # B = B X C
  elif $op == 5 then .out += [ $y % 8 ]              # OUT cmb mod
  elif $op == 6 then .B = (.A / pow(2;$y) | trunc)   # B = A SHIFT cmb
  elif $op == 7 then .C = (.A / pow(2;$y) | trunc)   # C = A SHIFT cmb
  end | .p += 2
) | .out | join(",") # Return final output
