#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs | (scan("\\d+|x")) | tonumber? // . ][1:]

| to_entries | map(select(.value|type == "number")) |

# Re-using math utils from 22nd day of 2019

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

def mul_inv($a;$b): div(add(EGCD($a;$b).bt[0];$b);$b).r;

def chinese_rem($mods; $rems): debug([$mods,$rems]) |
  reduce ([$mods,$rems] | transpose[] | map(b100k)) as [$mi, $ri] (
    {
      sum: (0|b100k),
      product: (reduce ($mods[]|b100k) as $m ((1|b100k); mul(.;$m)))
    };
    .p = div(.product;$mi).q |
    .sum = add(.sum; mul(mul($ri;mul_inv(.p;$mi));.p))
  ) | div(.sum;.product).r
;

# Output chinese remainder solution
chinese_rem(map(.value);map(.value - .key)) | toint|tonumber
