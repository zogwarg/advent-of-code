#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

(
  [
    inputs | scan("..?") / "" | map(tonumber)
  ]     | to_entries|map([.key,  .value   ] )
) as $f | # Get files by [ID, [size,free] ] #

def getFree($a;$i): .l[$a] as $s | # Lower index to start from  #
  if $s then {f,i:$s} # Search only until index of moving block #
    | until (.f[.i] == null or .f[.i][1][1] >= $a or .i >= $i; .i+=1)
    | if .i != true and .f[.i] and .i < $i then .i else false end
  else false end
;

# Move Blocks to the left, by descending FID #
{$f,l:[range(10)|0]} | (.i,.j) = ($f|last[0]) |until(.j == 0;
  .f[.i] as [$l,[$a,$b]] | # TODO early exit  #
  if $l > .j then .i -= 1  #   Already moved  #
  else
    getFree($a;.i) as $fi | .l[$a] = $fi |
    if $fi then
      #      Free space before moved block      #
      .f[.i-1][1][1] = .f[.i-1][1][1] + $a + $b |
      #             Move block into available free space             #
      .f[ .i ][1][1] = .f[$fi ][1][1] - $a      | .f[ $fi][1][1] = 0 |
      .f  =  .f[0:$fi+1]  +  [.f[.i]]  +  .f[$fi+1:.i]  +  .f[.i+1:] #
    else .i -= 1 end | .j -= 1
  end
) |

# In order Accessors. #
def f:  .f|first;
def fa: .f|first[1][0];
def fb: .f|first[1][1];

{f,i:0} | until((.f|length)==0;
  if fa > 0 then
    .c = .c + .i * f[0]
    | fa -= 1 | .i += 1
    | if fa == 0 and fb == 0 then .f = .f[1:] end
  elif fb > 0 then
    .i = .i + fb | .f = .f[1:]
  else
    .f = [] | .i += 1
  end
)

| .c # Output checksum
