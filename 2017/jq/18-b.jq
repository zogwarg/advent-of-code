#!/usr/bin/env jq -n -R -f

[ inputs / " " ] as $prgm |

# Wrapper for running program
def runCopy($regs;$i;$rcv;$in):
  {$prgm,l:($prgm|length),$i,$regs,out:[],$in,$rcv} |
  until (.i == .l or .rcv;
    .prgm[.i] as [$op, $a, $b] |

    def get_value($x):
      if $x | tonumber? // false then
        $x | tonumber
      else
        .regs[$x] // 0
      end
    ;

    if $op == "snd" then
      .out += [ get_value($a) ] | .i += 1
    elif $op == "set" then
      .regs[$a] = get_value($b) | .i += 1
    elif $op == "add" then
      .regs[$a] = (.regs[$a]//0) + get_value($b) | .i += 1
    elif $op == "mul" then
      .regs[$a] = (.regs[$a]//0) * get_value($b) | .i += 1
    elif $op == "mod" then
      .regs[$a] = (.regs[$a]//0) % get_value($b) | .i += 1
    elif $op == "rcv" then
      if .in | length > 0 then
        .regs[$a] = .in[0] | .in |= .[1:] | .rcv = false | .i += 1
      else
        .rcv = true
      end
    elif $op == "jgz" then
      if get_value($a) > 0 then
        .i += get_value($b)
      else
        .i += 1
      end
    end
  )
;

{ # Run two copies until deadlocked or completed
  A: {i:0,l:($prgm|length),in:[],rcv:false,regs:{p:0}},
  B: {i:0,l:($prgm|length),in:[],rcv:false,regs:{p:1}},
  B_outs: 0 # Cuunt the outputs for program "1"
} |
until ((.A.i == .A.l or .A.rcv) and (.B.i == .B.l or .B.rcv);
  runCopy(.A.regs;.A.i;.A.rcv;.A.in) as {$in,$out,$rcv,$i,$regs} |
  .A.i = $i | .A.rcv = $rcv | .A.in = $in | .A.out = [] | .A.regs = $regs |
  .B.in += $out |
  if .B.rcv and (.B.in | length > 0) then
    .B.rcv = false
  end |
  runCopy(.B.regs;.B.i;.B.rcv;.B.in) as {$in,$out,$rcv,$i,$regs} |
  .B.i = $i | .B.rcv = $rcv | .B.in = $in | .B.out = [] | .B.regs = $regs |
  .A.in += $out | .B_outs += ($out|length) |
  if .A.rcv and (.A.in | length > 0) then
    .A.rcv = false
  end
)

# Output
| .B_outs
