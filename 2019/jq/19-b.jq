#!/usr/bin/env jq -n -rR -f

# Define function, and inputs
{
  s: (inputs / "," | map(tonumber)), # Stack state
  c: 0,                              # Current  postion counter
  b: 0,                              # Relative  base  position
  in:  [],                           # Input  array, left first
  out: []                            # Output array, left first
} as $func |

def to_str($seq): $seq|map(tostring)|join(",")+",";

def toInt($bool): if $bool then 1 else 0 end;
def callFunc($func; $io):
  $func + $io | until(
    # Exit if opcode is not of type 1-9, or if output queue not empty.
    ([.s[.c] % 100] | inside([range(1;10)])|not) or (.out|length > 0);

    # Get opcode and parameter modes
    ( .s[.c] | [ . % 100 ]) as [$op] |
    ( .s[.c] | [ . / 100 |
      (. % 10              ),
      (. % 100 / 10 | floor),
      (. / 100      | floor)
    ]) as [ $ma, $mb, $mc ] |

    # Overly greedy parameter match
    .s[.c+1:.c+4] as [$a, $b, $c] |

    [
        if $ma == 1 then       $a
      elif $op == 3
       and $ma != 2 then       $a
      elif $op == 3 then    .b+$a
      elif $ma == 2 then .s[.b+$a] // 0
                    else .s[   $a] // 0 end,
        if $mb == 1 then       $b
      elif $mb == 2 then .s[.b+$b] // 0
                    else .s[   $b] // 0 end,
        if $mc == 2 then    .b+$c
                    else       $c       end
    ] as [$am,$bm,$cm] | # Apply param modes

      if $op == 1 then .c += 4 | .s[$cm] = $am + $bm # ADD
    elif $op == 2 then .c += 4 | .s[$cm] = $am * $bm # MULTIPLY
    elif $op == 3 then .c += 2 | .s[$am] = .in[0] | .in=.in[1:] # READ
    elif $op == 4 then .c += 2 | .out = .out + [$am] # WRITE
    elif $op == 5 then .c=(if $am==0 then .c+3 else $bm end) # JUMP-IF
    elif $op == 6 then .c=(if $am!=0 then .c+3 else $bm end) # JUMP-NE
    elif $op == 7 then .c += 4 | .s[$cm] = toInt($am <  $bm) # TEST-LT
    elif $op == 8 then .c += 4 | .s[$cm] = toInt($am == $bm) # TEST-EQ
                  else .c += 2 | .b = .b + $am end # RELATIVE-BASE UPD

  )
  # Provide termination state.
  | if .s[.c] % 100 == 99 then .term = true else . end
;

def line($y;$min): # Get first an last x, in range of beam for: line=y
  [label $out | foreach (
    $y | range($min;$y) as $x |# Only smart check Xs starting from min
    callFunc($func; {in:[$x,$y]}) | {$x,$y, o: .out[0]}
  ) as {$x,$y,$o} (null;      # ┌───── Stop after, x leaves beam
    if .s == 1 and $o == 0 then break $out end | .s = $o; # beam
    if $o == 1 then $x else empty end
  )] | [ first, last ]
;

def test($y;$min): line($y; $min) as [$f,$l] |
  if $f == null then #─ Handle early misses
    [0, 0, false]    # ┌── Is line 100 wide
  elif $l - $f < 99 then [ $f, false ] else
    line($y+99;$f) as [$ff,$ll]| # 100 down
    [ # Is opposite 100x100 corner, in beam
      $f, $l, ( $ll - $ff >= 99 ) and ($l - $ff >= 99)
    ] | debug({$f,$l,$ff,$ll})
  end
;

[ # Get inital low high powers of two for binary search
  [1, 0] | recurse(test(.[0]; .[1]) as [$min, $x, $t] |
    if $t then empty else
      [
        .[0] * 2, # Increase power of 2
        $min,     # Safe min_x, cutoff.
        $x        # Edge of beam last x
      ]
    end
  ) # Penultimate     # Ultimate   # Ultimate 2^i
] | [[nth(-2),false], [last,true], (last[0]|log2)] as [$low,$high,$i]|

nth(
  $i-1; #                Binary search                    #
  [$low, $high] | recurse ( . as [$a,$b] | debug({$a,$b}) |
    (($a[0][0]+$b[0][0]) / 2 ) as $mid | $a[0][1] as $min |
    test($mid; $min) as [$min,$x,$t] |  # Test mid point  #
    if $t then [$a,[[$mid,$min,$x],$t]] #    [lo,mid]     #
          else [[[$mid,$min,$x],$t],$b] #    [mid,hi]     #
    end
  )
) | last | debug as [[$y,$min,$x]] |

first(
  range($y-10;$y) as $y | test($y;$min-50)
  | [ .[1], $y, .[-1] ]  # Check before last, because of jagged beam
  | debug | select(.[2]) # Keep the first: x,y that can actually fit
) as [$x, $y] |

if  [ # Assert that closest box, touches top edge of beam
      ([$x,$y], [$x-99, $y+99], [$x-100, $y+99]) as $in |
      callFunc($func;{$in}).out[0]
    ] | debug!=[1,1,0] then "Assumptions don't hold" | halt_error end|

# Output closest point
($x - 99) * 10000 + $y
