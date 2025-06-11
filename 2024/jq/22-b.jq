#!/bin/sh
# \
exec jq -n -f "$0" "$@"

#────────────────── Big-endian to_bits ───────────────────#
def to_bits:
  if . == 0 then [0] else { a: ., b: [] } | until (.a == 0;
      .a /= 2 |
      if .a == (.a|floor) then .b += [0]
                          else .b += [1] end | .a |= floor
  ) | .b end;
#────────────────── Big-endian from_bits ────────────────────────#
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

#  Still slow, because of from_bits  #
def to_price($p): $p | from_bits % 10;

# Option to run in parallel using xargs, Eg:
#
# seq 0 9 | \
# xargs -P 10 -n 1 -I {} bash -c './2024/jq/22-b.jq input.txt \
# --argjson s 10 --argjson i {} > out-{}.json'
# cat out-*.json | ./2024/jq/22-b.jq --argjson group true
# rm out-*.json
#
# Speedup from naive ~50m -> ~1m
def parallel: if $ARGS.named.s and $ARGS.named.i  then
   select(.key % $ARGS.named.s == $ARGS.named.i)  else . end;

#════════════════════════════ X-GROUP ═══════════════════════════════#
if $ARGS.named.group then

# Group results from parallel run #
reduce inputs as $dic ({}; reduce (
      $dic|to_entries[]
  ) as {key: $k, value: $v} (.; .[$k] += $v )
)

else

#════════════════════════════ X-BATCH ═══════════════════════════════#
reduce (
  [ inputs ] | to_entries[] | parallel
) as { value: $in } ({};  debug($in) |
  reduce range(2000) as $_ (
    .curr = ($in|to_bits) | .p = to_price(.curr) | .d = [];
    .curr |= next | to_price(.curr) as $p
    | .d = (.d+[$p-.p])[-4:]  | .p = $p # Four differences to price
    | if .a["\($in)"]["\(.d)"]|not then # Record first price
         .a["\($in)"]["\(.d)"] = $p end # For input x 4_diff
  )
)

# Summarize expected bananas per 4_diff sequence #
| [ .a[] | to_entries[] ]
| group_by(.key)
| map({key: .[0].key, value: ([.[].value]|add)})
| from_entries

end |

#═══════════════════════════ X-FINALLY ══════════════════════════════#
if $ARGS.named.s | not then

#     Output maximum expexted bananas      #
to_entries | max_by(.value) | debug | .value

end
