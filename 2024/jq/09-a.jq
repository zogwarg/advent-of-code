#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

(
  [
    inputs | scan("..?") / "" | map(tonumber)
  ]     | to_entries|map([.key,  .value   ] )
) as $f | # Get files by [ID, [size,free] ] #

def f: .f|first; # In order accessor #
def r: .f|last ; # Reverse  accessor #

{$f,i:0} | until((.f|length)==0;
  if f[1][0] > 0 then
    .c = .c + .i * f[0] | f[1][0] -= 1
    | if f[1][0] == 0 and f[1][1] == 0 then .f = .f[1:] end
  elif f[1][1] > 0 and r[1][0] > 0 then
    .c = .c + .i * r[0] | (f[1][1],r[1][0]) -= 1
    | if r[1][0] == 0 then .f = .f[:-1] end
    | if f[1][1] == 0 then .f = .f[1:]  end
  else .f = [] end | .i += 1
)

| .c # Output checksum
