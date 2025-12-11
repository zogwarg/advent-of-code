#!/bin/sh
# \
exec jq -cn -R -f "$0" "$@"

# "Not working!" | halt_error | # Solved with python in the meantime

def GCD($a; $b): if $b == 0 then $a else GCD($b; $a % $b) end;
def mul_inv($a; $b):
  if $b == 0 then
    1
  else
    {$a, $b, x0: 0, x1: 1} | until (.a <= 1;
      .q = (.a / .b | floor) |
      .r = (.a % .b ) |
      .a = .b | .b = .r |
      .x = ( .x1 - .q * .x0 ) |
      .x1 = .x0 | .x0 = .x
    ) |
    if .x1 < 0 then .x1 + $b else .x1 end
  end
;

def idMat($n):
  [
    range($n) as $i | [
    range($n) as $j | if $i == $j then 1 else 0 end
    ]
  ]
;

def addVar($A;$B): [$A,$B|type[0:1]] as $T |
  if $T == ["n", "n"] then
    $A + $B
  elif $T == ["n", "a"] then
    addVar([$A];$B)
  elif $T == ["a", "n"] then
    addVar($A;[$B])
  else
    [
      (
        [
          $A[], $B[] | numbers
        ] | add
      ),
      (
        [ $A[], $B[] | arrays ]
        | group_by(last)[]
        | [ ([ .[][0] ] | add), .[0][1] ]
      )
    ]
  end
;

def mulVar($A;$B): [$A,$B|type[0:1]] as $T |
  if $T == ["n", "n"] then
    $A * $B
  elif $T == ["n", "a"] then
    [
      (
        [
          $B[] | numbers * $A
        ] | add
      ),
      (
        $B[] | arrays | .[0] *= $A
      )
    ]
  else
    "mulVar(var;var) Not Implemented!"
  end
;

def multiplyMat($A;$B):
  reduce range($A|length) as $i (
    [];
    reduce range($B[0]|length) as $j (
      .;
      .[$i][$j] = reduce range($A[0]|length) as $k (
        0;
        . + $A[$i][$k] * $B[$k][$j]
      )
    )
  )
;

def mulVarMat($A;$B):
  reduce range($A|length) as $i (
    [];
    reduce range($B[0]|length) as $j (
      .;
      .[$i][$j] = reduce range($A[0]|length) as $k (
        0;
        addVar(.; mulVar($A[$i][$k];$B[$k][$j]))
      )
    )
  )
;

def getSAT:
  def swapLine($a;$b):
    .A[$a] as $line | .A[$a] = .A[$b] | .A[$b] = $line |
    .S[$a] as $line | .S[$a] = .S[$b] | .S[$b] = $line
  ;
  def swapColumn($a;$b):
    reduce range(.N) as $i (.;
      .A[$i][$a] as $X | .A[$i][$a] = .A[$i][$b] | .A[$i][$b] = $X
    ) |
    reduce range(.M) as $i (.;
      .T[$i][$a] as $X | .T[$i][$a] = .T[$i][$b] | .T[$i][$b] = $X
    )
  ;
  def addColumn($a;$b;$n):
    (
      idMat(.M) | [
        (.[$a][$b] = $n),
        (.[$a][$b] = -$n)
      ]
    ) as [$add, $min] |
    .A = multiplyMat(.A; $add) | .T = multiplyMat(.T; $add) |
    .Tinv = multiplyMat($min; .Tinv)
  ;

  def addLine($a;$b;$n):
    (idMat(.N) | .[$b][$a] = $n ) as $add |
    .A = multiplyMat($add; .A) | .S = multiplyMat($add; .S)
  ;

  [.,.[0]|length] as [$N, $M] |
  {
    A: ., Ap: ., $N, $M, S: idMat($N), T: idMat($M) #,Tinv: idMat($M)
  } |

  ([$N,$M]|min) as $L |

  reduce range($L) as $a (.;
    if (.A[$a][$a]|abs) != 1 then
      [[
        .A
        | to_entries[$a:][] | .key as $i | .value
        | to_entries[$a:][] | .key as $j | .value | select(. != 0)
        | {$i, $j, v: .}
      ] | min_by(.v != 1,(.v|abs),.j,.i)] as [{ $i,$j, $v}]
        | if $i then
            if (.A[$a][$a]|abs) == 0 or ($v|abs) < (.A[$a][$a]|abs) then
              swapLine($a;$i) | swapColumn($a;$j)
            end
          end
    end |

    .A[$a][$a] as $x |

    if ($x|abs) != 1 and $x != 0 then
      [first(
        .A
        | to_entries[$a:][] | .key as $i | .value
        | to_entries[$a:][] | .key as $j | .value
        | select($i == $a or $j == $a)
        | select([$i,$j] != [$a,$a])
        | select(GCD($x;.)|abs==1)
        |     {$i, $j,  v: .}
      )] as [ {$i, $j, $v   } ] |

      if $i then
        (mul_inv($x|abs;$v|abs)) as $inv   |
        ($inv*($x|abs)-1|./($v|abs)) as $m |

        if $i == $a then
          if $x < 0 then addColumn($a;$a;-1) end |
          if $v < 0 then addColumn($j;$j;-1) end
        else
          if $x < 0 then addLine($a;$a;-1) end |
          if $v < 0 then addLine($j;$j;-1) end
        end |

        if $i == $a then
          addColumn($a;$a;$inv) | addColumn($j;$a;-$m)
        else
            addLine($a;$a;$inv) | addLine($i;$a;-$m)
        end
      end
    end |

    .A[$a][$a] as $x |

    if ($x|abs) != 0 then
      reduce (
        [ .A[][$a] ] | to_entries[$a+1:][] | select(.key!=$a and .value != 0)
      ) as {key: $b, value: $n} (
        .;

        .A[$a][$a] as $x |

        if ($x|abs) != 1 then
          if $x < 0 then addLine($a;$a;-1) end |
          if $n < 0 then addLine($b;$b;-1) end |
          .A[$a][$a] as $x | .A[$b][$a] as $n |
          GCD($x;$n) as $g |
          ( $x / $g ) as $g1 | ($n / $g ) as $g2 |
          addLine($b;$b;$g1) | addLine($a;$b;-$g2)
        else
          addLine($a; $b; -$x * $n)
        end
      ) |
      reduce (
        .A[$a] | to_entries[$a+1:][] | select(.key != $a and .value != 0)
      ) as {key: $b, value: $n} (
        .;
        if ($x|abs) != 1 then
          if $x < 0 then addColumn($a;$a;-1) end |
          if $n < 0 then addColumn($b;$b;-1) end |
          .A[$a][$a] as $x | .A[$a][$b] as $n |
          GCD($x;$n) as $g |
          ( $x / $g ) as $g1 | ($n / $g ) as $g2 |
          addColumn($b;$b;$g1) | addColumn($a;$b;-$g2)
        else
          addColumn($a; $b; -$x * $n)
        end
      )
    end |

    .A[$a][$a] as $x |

    if $x < 0 then addColumn($a;$a;-1) end
  ) |

  ([
    range(.N) as $i |
    .A[$i][$i] | select(. != 0 and . != null) | $i + 1
  ]| max) as $N |

  if [ range($N) as $i | .A[$i][$i] ] | unique | contains([0])
  then
    "Bad Diagonal!" | halt_error
  end | { A: .Ap, B: .A, S, T, $N }
;

# With: B = S A T; Y = Tinv X
#
# A      X =        C
# B Tinv X =      S C
#        Y = Binv S C
#
# X = T Binv S C

def solve($A;$C): ($C|length) as $N | ($A[0]|length) as $M
   | $A | getSAT

   | .Binv = ( .B | transpose | map(map(if . != 0 then 1 / . end )) )
   | .Y = multiplyMat(multiplyMat(.Binv;.S);[$C]|transpose)[0:.N]
   | ([.T,.Y|length]|first-last) as $L
   | .Y = .Y + [
      [[0,[1,"a"]]],
      [[0,[1,"b"]]],
      [[0,[1,"c"]]]
    ]
   | .Y = .Y[0:.T|length]
   | .X = mulVarMat(.T;.Y)
   | .sum = reduce .X[1:][][0] as $x (.X[0][0]; addVar(.; $x))

   # TODO: Solve using inequalities instead
   |   if $L == 0 then .sum
     elif $L == 1 then
       [
          range(-50;50) as $a |
          (.X[][][],.sum[]|arrays) |= (first * $a) |
          (.X[][]  ,.sum ) |= add  |
          select(all(.X[][]; . >= 0)) | debug(.X) | .sum
       ] | min
     elif $L == 2 then
       [
          range(-50;50) as $a | range(-50;50) as $b |
          (.X[][][],.sum[]|arrays|select(last=="a")) |= (first * $a) |
          (.X[][][],.sum[]|arrays|select(last=="b")) |= (first * $b) |
          (.X[][]  ,.sum ) |= add |
          select(all(.X[][]; . >= 0)) | debug(.X) | .sum
       ]  | min
     elif $L == 3 then
       [
          range(-50;50) as $a | debug({$a}) | range(-50;50) as $b | range(-50;50) as $c |
          (.X[][][],.sum[]|arrays|select(last=="a")) |= (first * $a) |
          (.X[][][],.sum[]|arrays|select(last=="b")) |= (first * $b) |
          (.X[][][],.sum[]|arrays|select(last=="c")) |= (first * $b) |
          (.X[][]  ,.sum ) |= add |
          select(all(.X[][]; . >= 0)) | debug(.X) | .sum
       ]  | min
     else
      "Too Many Vars!" | halt_error
     end
;

[
  inputs / " " | map(
    [ scan("[.#]|\\d+") | tonumber? // if . == "." then 0 else 1 end ]
  )
] |

[
  to_entries[] | . as {$key} | debug({key}) | .value |
  {
    buttons: .[1:-1],
    joltages: .[-1]
  }
  |
  .mat = reduce (
    range(.buttons|length)
  ) as $j (
    reduce (.buttons|to_entries[]) as {key: $i, value: $v} (
      [];
      .[$v[]][$i] = 1
    );
    .[][$j] += 0
  )
  | solve(.mat;.joltages)
] | add
