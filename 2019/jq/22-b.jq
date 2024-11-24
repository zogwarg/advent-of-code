#!/usr/bin/env jq -n -rR -f

                  # Get all shuffle operations
[ inputs | [ scan("^[cd]"), (scan("-?\\d+") | tonumber) ]] as $shuf |

# Because here the numbers get very large and JQ only uses floats 64,
# Of mantissa of size at most 53 we need to improvise some math utils

#═════════════════════════ Bootstrap Utils! ═════════════════════════#

# Represent number in base 100K
def b100k:        (tostring|gsub("-";"")) as $n | ($n|length) as $l |

  if copysign(1;.) == -1 and $l > 15 then
    "Can't do large negatives: \($n)" | halt_error
  elif ($n|test("[.+E]")) then
    "Can't do non-int numbers: \($n)" | halt_error
  else
    {
      s: copysign(1;.),
      b: [
        range(0;$l;5) as $i |
        $n[($l-$i-5|if . < 0 then 0 end):$l-$i] | tonumber
      ]
    }
  end
;                # Transforms number back to decimal form
def toint: "-\(.b|reverse|map("00000\(tostring)"[-5:])|add)"
           [(.s+1)/2:]| gsub("^(?<s>-?)0+";"\(.s)") |
                      if . == "" then "0" end
;
def print($key): debug(  # Debug pretty-printing functions
  {"\($key)": (((..|objects)|select(.s and .b)) |= toint )}
);                    def e($err): $err | halt_error;

#═════════════════════════ Math Utilities! ══════════════════════════#

def neg: .s = [0,-1,1][.s];                        #   Change sign   #
def trim: until(.[-1] != 0 or length == 1; .[:-1]);# Trim trailing 0 #

def sub($a;$b): [$a.b,$b.b|length] as [$al,$bl] |
  if   [$a,$b|.s]==[-1,1] then sub($b;$a)
  elif [$a,$b|.s]!=[1,-1] then e("Not implemented: sub(\($a);\($b))")
  elif $al < $bl or ($al == $bl and $a.b[$al-1] < $b.b[$bl-1]) then
    sub($b|neg;$a|neg) | neg
  else
    reduce (
      [$a,$b|.b]| transpose[] | (.. | nulls) |= 0
    ) as [$i,$j] ( {c:0, i:0, b:[] }; # c:carry, i:pos, b:result_arr
      ($i - $j + .c ) as $s    | ((1e5 + $s) % 1e5) as $k
      | .c = ( $s - $k ) / 1e5 |     .b[.i] = $k           | .i += 1
    ) | { s: 1, b: (.b|trim) }
  end
;
def add($a;$b):
  if [$a,$b|.s] == [-1,-1] then add($a|neg;$b|neg)|neg
  elif [$a,$b|.s] != [1,1] then sub($a;$b)
  else
    reduce (
      [$a,$b|.b] | transpose[]
    ) as [$i,$j] ( {c:0, i:0, b:[] }; # c:carry, i:pos, b:result_arr
      ( .c + $i + $j ) as $s | ($s % 1e5) as $k | .c = ($s - $k)/1e5
      | .b[.i] = $k                             | .i += 1
    ) | if .c > 0 then .b[.i] = .c end # Final carry
      | { s: 1, b: (.b|trim) }
  end
;
def mul($a;$b):
    if $a.b == [0] or $b.b == [0] then { s: 1, b: [0] }
  # elif  $a  == $R then { s: $b.s, b: ([0,0,0] + $b.b) }
  # elif  $b  == $R then { s: $a.s, b: ([0,0,0] + $a.b) }
  # Speedup ^ multiplication for 100000000000000, shift
  else
    reduce (
      $a.b | to_entries[] as {key: $i, value: $ab }
           | reduce $b.b[] as $bb ({c:0,i:0,b:[]}; # carry,pos,r_arr
               ( $ab * $bb + .c ) as $s
               | ($s % 1e5) as $k
               | .c = ($s - $k) / 1e5
               | .b[.i] = $k
               | .i += 1
             ) | if .c > 0 then .b[.i] = .c end
           | [ limit($i; repeat(0)) ] + .b
           | { s: 1, b: . }
    ) as $i ({s:1,b:[0]}; add(.;$i)) | .s = $a.s * $b.s
  end
;
def gt($a;$b): [$a.b,$b.b|length] as [$al,$bl] |
  if $al != $bl then $al > $bl else ($a.b|reverse)>($b.b|reverse) end
;
def div($n;$d): [$n.b,$d.b|length] as [$nl,$dl] |
  if   $d.b == [0] then e("Can't divide by zero: div(\($n);\($d))")
  elif $d.b == [1] then
    {
      q: { s: $n.s, b: $n.b },
      r: { s: 1, b: [0] },
    }
  elif $nl < $dl or ($nl == $dl and $n.b[$nl-1] < $d.b[$dl-1]) then
    {
      q: { s: 1, b: [0] },
      r: { s: $n.s, b: $n.b},
    }
  #elif $d == $R then # Speed up division for 1000000000000000, shift
  #  {
  #    q: { s: $n.s, b: ($n.b[3:] |trim) },
  #    r: { s: $n.s, b: ($n.b[0:3]|trim) }
  #  }
  else {r: $n.b, q:[],i: ($nl - $dl), j: ($nl), w: $dl} |
    until (.done;
      ( {s: 1, b: .r[.i:.j]} ) as $r | # Implementing long division
      if all($r.b[]; . == 0) then      #    Using binary search
        .
      else
        last(limit (18;{
          l: {s:1, b:[0],     gt: false, m: {s:1, b:[0]} },
          h: {s:1, b:[99999], gt: true                   },
        } | recurse (
          .m = { s: 1, b: [(.l.b[0] + .h.b[0]) / 2 | floor ] }
          | .m.r = mul($d; .m)  | .m.gt = gt(.m.r; $r)
          | if .m.gt then {l, h:.m} else {l:.m, h} end
        )).l) as { b: $q, r: $mr }
        | .q = $q + .q #──Add to quotient  ┌─Update remainder
        | .r[.i:.j] = add($r;$mr|neg).b + [0] | .r = .r[:$nl]
      end |

      # - Checking if done + update boundaries of remainder - #
      if   gt($d;{b:.r[.i:.j]}) and .i > 0  then .i = .i - 1
      elif gt($d;{b:.r[.i:.j]}) and .i == 0 then .done = true
      else    .j = .j - 1 | .i = ([.i - 1, 0]|max)      end |
      until (  .r[.j-1] != 0 or .j == 0  ;  .j = .j - 1   ) |
      if .i == 0 and gt($d;{b:.r[.i:.j]}) then .done = true end

    ) |
    {
      q: {s: ($n.s*$d.s), b:(.q|trim)},
      r: {s: ($n.s),      b:(.r|trim)},
    }
  end
;

#══════════════════════════ Extended GCD! ═══════════════════════════#

def EGCD($a;$b):
  { s: (0|b100k), os: (1|b100k), r: $b, or: $a } |
  until (.r.b == [0]; .i += 1 |
    div(.or; .r) as $d | .r as $r | .s as $s |
    .r = $d.r | .or = $r |
    .s = add(.os; mul($d.q;.s)|neg) | .os = $s |
    if .i > 500 then
      "EGCD taking too long: EGCD(\($a);\($b))" | halt_error
    end
  )
  | if $b.b != [0] then .bt = div(add(.or; mul(.os;$a)|neg);$b).q end
  | { bt: [.os, .bt // 0], gcd: .or }
;

#═════════════════════════ Main Solution! ═══════════════════════════#

[
     (119315717514047|b100k),              # Deck size
  add(119315717514047|b100k;{s:-1,b:[1]}), # Deck size minus one
      101741582076661,                     # Number of iterations
       (2020|b100k),                       # Card position to check
       (   1|b100k),                       # One
       (   0|b100k)                        # Zero
] as [ $N, $N_1, $T, $at, $one, $zero ] |

[ #   Getting foward shuffle for checking compose consistency   #
  $shuf[] | .[1] |= ( if . then b100k end ) | . as [$op, $n ]
          | [    # Getting the F params   (     a     ,    b    )
                if $op == "d" and $n then (    $n    ),( $zero  )
              elif $op == "d"        then ( $one|neg ),(  $N_1  )
                                     else (   $one   ),( $n|neg )
                                      end
            ]
] as $fwd |

[ # Getting reversed shuffle operations, to check card original index
  $shuf   | reverse[]
          | .[1] |= ( if . then b100k end ) | . as [$op, $n ]
          | def inv($a): div(add(EGCD($a;$N).bt[0];$N);$N).r;
            [    # Getting the iF params  (     a     ,    b    )
                if $op == "d" and $n then (  inv($n) ),( $zero  )
              elif $op == "d"        then ( $one|neg ),(  $N_1  )
                                     else (   $one   ),(   $n   )
                                      end
            ]
] as $rev |

def compose($F):                             # Compose the operations
  reduce $F[] as [$a, $b] ({a: $one, b: $zero};
    .a = div(    mul(.a;$a)    ;$N).r      | # a = na * a     mod N
    .b = div(add(mul($a;.b);$b);$N).r      | # b = na * b + b mod N
    if .a.s == -1 then .a = add($N;.a) end | #
    if .b.s == -1 then .b = add($N;.b) end | # Staying positive
    debug([.a,.b|toint] | "\(.[0]) \(.[1])")
  ) | [[.a, .b]]
;

{ rev: compose($rev), fwd: compose($fwd) } | . as {$rev,$fwd} |
if   [ compose(.rev + .fwd)[][].b ] != [[1],[0]]
then e("Composing fwd + rev did not result in identity.")
end| # Math sanity checking

reduce  range($T|logb) as $i ({ revs: [.rev] };
  .revs[$i+1] = compose(.revs[-1] + .revs[-1])
) # Getting the powers of 2, revs compositions
|
reduce (
  {
    $T, binary: [] # Transform Iterations number to binary form
  }
  | until( .T==0; .binary[.T|logb] = 1 | .T = .T - pow(2;(.T|logb)) )
  | .binary  |  to_entries[] | select(.value)
) as {key: $i} ({revs, comp: [[$one, $zero]]};
  .comp = compose(.comp+.revs[$i]) # Compose using the 2^N primitives
) |     . as {comp:[[$a,$b]]}

# After all that: What card ends at 2020?
| div(add(mul($a;$at);$b);$N).r  | toint
