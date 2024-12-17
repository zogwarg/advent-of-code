#!/usr/bin/env jq -n -rR -f

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

[ inputs | scan("\\d+") | tonumber ] | .[3:] |= [.]
| . as [$A,$B,$C,$pgrm] |


# Assert  #
if  [first(
        range(8) as $x |
        range(8) as $y |
        range(8) as $_ |
        [
          [2,4],  # B = A mod 8            # Zi
          [1,$x], # B = B xor x            # = A[i*3:][0:3] xor x
          [7,5],  # C = A << B (w/ B < 8)  # = A(i*3;3) xor x
          [1,$y], # B = B xor y            # Out[i]
          [0,3],  # A << 3                 # = A(i*3+Zi;3) xor y
          [4,$_], # B = B xor C            #               xor Zi
          [5,5],  # Output B mod 8         #
          [3,0]   # Loop while A > 0       # A(i*3;3) = Out[i]
        ] | select(flatten == $pgrm)       #         xor A(i*3+Zi;3)
      )] == []                             #         xor constant
then "Reverse-engineering doesn't neccessarily apply!" | halt_error
 end |

#  When minimizing higher bits first, which should always produce   #
# the final part of the program, we can recursively add lower bits  #
#          Since they are always stricly dependent on a             #
#                  xor of Output x high bits                        #

def run($A):
  # $A is now always a bit array                    #
  #                 ┌──i is our shift offset for A  #
  { p: 0, $A,$B,$C, i: 0} | until ($pgrm[.p] == null;

    $pgrm[.p:.p+2] as [$op, $x]       | # Op & literal operand
    [0,1,2,3,.A,.B,.C,null][$x] as $y | # Op &  combo  operand

    # From analysis all XOR operations can be limited to 3 bits  #
    # Op == 2 B is only read from A                              #
    # Op == 5 Output is only from B (mod should not be required) #
      if $op == 0 then .i += $y
    elif $op == 1 then .B = xor(.B|to_bits[0:3]; $x|to_bits[0:3])
    elif $op == 2
     and $x == 4  then .B = (.A[.i:.i+3] | from_bits)
    elif $op == 3
     and (.A[.i:]|from_bits) != 0
                  then .p = ($x - 2)
    elif $op == 3 then .
    elif $op == 4 then .B = xor(.B|to_bits[0:3]; .C|to_bits[0:3])
    elif $op == 5 then .out += [ $y % 8 ]
    elif $op == 6 then .B = (.A[.i+$y:][0:3] | from_bits)
    elif $op == 7 then .C = (.A[.i+$y:][0:3] | from_bits)
    else "Unexpected op and x: \({$op,$x})" | halt_error
    end | .p += 2
  ) | .out;

[ { A: [], i: 0 } | recurse (
    #  Keep all candidate A that produce the end of the program,  #
    #  since not all will have valid low-bits for earlier parts.  #
    .A = ([0,1]|combinations(6)) + .A | # Prepend all 6bit combos #
    select(run(.A) == $pgrm[-.i*2-2:] ) # Match pgrm from end 2x2 #
    | .i += 1
    # Keep only the full program matches, and convert back to int #
  ) | select(.i == ($pgrm|length/2)) | .A | from_bits
]

| min # From all valid self-replicating intputs output the lowest #
