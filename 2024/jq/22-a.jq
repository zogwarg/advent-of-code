#!/bin/sh
# \
F="$0" I="$1" exec sh -c '( seq 0 9 | xargs -P 10 -n 1 -I {} bash -c '\''jq -n -f "$F" --argjson p 10 --argjson s {} "$I" > out-{}.json'\'' ) && (cat out-*.json | jq -nf "$F" --argjson group 1 ) && rm out-*.json'

#─────────── Big-endian to_bits and from_bits ────────────#
def to_bits:
  if . == 0 then [0] else { a: ., b: [] } | until (.a == 0;
      .a /= 2 |
      if .a == (.a|floor) then .b += [0]
                          else .b += [1] end | .a |= floor
  ) | .b end;
def from_bits: [ range(length) as $i | .[$i] * pow(2; $i) ] | add;

( # Get index that contribute to next xor operation.
  def xor_index(a;b): [a, b] | transpose | map(add);
  [ range(24) | [.] ]
  | xor_index([range(6) | [-1]] + .[0:18] ; .[0:24])
  | xor_index(.[5:29] ; .[0:24])
  | xor_index([range(11) | [-1]] + .[0:13]; .[0:24])
  | map(
      sort | . as $indices | map(
        select( . as $i |
          $i >= 0 and ($indices|indices($i)|length) % 2 == 1
        )
      )
    )
) as $next_ind |

# Optimized Next, doing XOR of indices simultaneously a 2x speedup #
def next: . as $in | $next_ind | map( [ $in[.[]] // 0 ] | add % 2 );

# Parralel mode speedup from naive ~10m -> ~35s
def parallel: if $ARGS.named.p and $ARGS.named.s  then
   select(.key % $ARGS.named.p ==  $ARGS.named.s) else . end ;

#════════════════════════════ X-GROUP ═══════════════════════════════#
if $ARGS.named.group then reduce inputs as $i (0; . + $i) else
#════════════════════════════ X-BATCH ═══════════════════════════════#
reduce (
  [ inputs ] | to_entries[] | parallel
) as { value: $in } (0;
  . + (
    ( reduce range(2000) as $_ ($in|debug|to_bits; next) )
    | from_bits
  )
)

end
