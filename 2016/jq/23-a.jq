#!/usr/bin/env jq -n -R -f

# Get program
[ inputs / " " | .[1:][] |= if tonumber? // false then tonumber else . end ] |

. as $orig |

def compile($asmb):
  # Detect addition jnz -2 loops and recompile to more
  # efficient version of inc -> inc a b -> a += b
  reduce (
    [$asmb[]|[.[0],.[-1]]] | indices([["jnz",-2]]) | .[]
  ) as $i ($asmb;
    .[$i][1] as $dec |

    if .[$i-2][0] == "inc" and .[$i-1] == ["dec",$dec] then
      .[$i-2] += [$dec]        | # inc a -> inc a b
      .[$i-1] = ["cpy",0,$dec]   # dec b -> cpy 0 b
    end
  ) |
  # Detect multiplication jnz -5 loops and recompile to
  # new efficient instruction -> mul a b -> a *= b
  reduce (
    [.[]|[.[0],.[-1]]] | indices([["jnz",-5]]) | .[]
  ) as $i (.;
    .[$i][1] as $d |

    .[$i-7] as [$op7, $a  , $td7] | # cpy a d
    .[$i-6] as [$op6, $tz6, $ta6] | # cpy 0 a
    .[$i-5] as [$op5, $b  , $c  ] | # cpy b c
    .[$i-4] as [$op4, $ta4, $tc4] | # inc a c
    .[$i-3] as [$op3, $tz3, $tc3] | # cpy 0 c
    .[$i-2] as [$op2, $tc2, $tr2] | # jnz c -2
    .[$i-1] as [$op1, $td1      ] | # dec d

    if (
        [$op7,$op6,$op5,$op4,$op3,$op2,$op1] ==
        ["cpy","cpy","cpy","inc","cpy","jnz","dec"]
       ) and (
        $a != $b and $a != $c and $a != $d and
        $b != $c and $b != $d and $c != $d and
        $a == $ta6 and $a == $ta4 and
        $c == $tc4 and $c == $tc3 and $c == $tc2 and
        $d == $td7 and $d == $td1 and
        $tz6 == 0 and $tz3 == 0 and $tr2 == -2
       )
    then
      .[$i-7:$i] = [
        ["mul", $a, $b],
        ["cpy", 0, $c],
        ["cpy", 0, $d],
        ["cpy", 0, $d],
        ["cpy", 0, $d],
        ["cpy", 0, $d],
        ["cpy", 0, $d]
      ]
    end
  )
;

{
  raw: $orig,           # Keep uncompiled version, for toggle
  asmb: compile($orig), # Compile to more efficient asmb
  i: 0,                 #
  regs: {a:7}           # Init a = 7
} |

until(.asmb[.i] | not;
  def get_value($x):
    if $x | tonumber? // false then $x | tonumber
    else .regs[$x] // 0 end
  ;
  def get_inc($x): if $x then get_value($x) else 1 end;

 .asmb[.i] as [$op, $a, $b] |

  if $op == "cpy" and ( $b|type == "string" ) then
    .regs[$b] = get_value($a) | .i +=1
  elif $op == "inc" then
    # Enhanced INC instruction
    .regs[$a] += get_inc($b) | .i += 1
  elif $op == "dec" then
    .regs[$a] -= 1 | .i += 1
  elif $op == "jnz" and get_value($a) != 0 then
    .i += ( get_value($b) | if . == 0 then 1 end)
  elif $op == "tgl" then
    (.i + get_value($a)) as $j |
    # Toggle one instruction, in raw stack
    .raw |= ( .[$j][0] |= {
        "dec": "inc",
        "tgl": "inc",
        "inc": "dec",
        "cpy": "jnz",
        "jnz": "cpy"
    }[. // "x"]) |
    # Recompile execution stack
    .asmb = compile(.raw) |
    .i += 1
  elif $op == "mul" then
    # New dedicated mul instruction
    .regs[$a] = get_value($a) * get_value($b) |
    .i += 1
  else
    .i += 1
  end
)

# Output final value in register a
| .regs.a
