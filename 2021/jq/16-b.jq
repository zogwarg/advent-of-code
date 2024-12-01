#!/usr/bin/env jq -n -R -f

def ctob($f): [[0,1]|combinations(4)]["0123456789ABCDEF"|index($f)][];
def btoi:     [pow(2;reverse|indices(1)[])] | add + 0;
def liti:      first(range(100) as $i | select(.[$i*5] == 0) | $i);
def glit:      liti as $i | .[:5*$i+5] | del(.[range($i+1)*5]) | btoi;

[ inputs | ctob(scan(".")) ] | # Get BITS stream

def parse:
  def head:
    # Get header of first packet in stream
    [.[0:3], .[3:6] | btoi ] as [$v, $t] |
    # Literal type          # Head Value  # Stream Tail
    if  $t  == 4 then .[6:] | {l: glit }, .[5*liti+5:]
    # Operator          # Absolute Length in bits
    elif .[6] == 0 then (.[7:7+15]|btoi) as $len |
      # HEAD Get subpackets, recursively   # Stream Tail
      { c: [ .[7+15:7+15+$len] | parse ]}, .[7+15+$len:]
    # Operator          # Number of child packets
    elif .[6] == 1 then (.[7:7+11]|btoi) as $nc |
      # Read nc times              # Parse last tail  #
      [limit($nc+1; [.[7 + 11:]] | recurse(last|[head]))] as $R |
      # Head                     # Stream Tail
      { c: $R[1:] | map(first)},   $R[-1][1]
    else "Unexpected bits: \(.[0:7])" | halt_error
    end | objects += {$v,$t}
  ;
  [head] | first, (last|select(length>6)|parse)
;

# Calculate!
parse | walk (
    if .l? // false     then .l
  elif (.t? // -1) == 0 then .c | add
  elif (.t? // -1) == 1 then reduce .c[] as $i (1; . * $i)
  elif (.t? // -1) == 2 then .c | min
  elif (.t? // -1) == 3 then .c | max
  elif (.t? // -1) == 5 then if .c[0] > .c[1] then 1 else 0 end
  elif (.t? // -1) == 6 then if .c[0] < .c[1] then 1 else 0 end
  elif (.t? // -1) == 7 then if .c[0] ==.c[1] then 1 else 0 end
  elif type == "object" then "Unexpected node: \(.)"|halt_error
   end
)
