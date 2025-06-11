#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

{
  s: (inputs / "," | map(tonumber)),
  c: 0,
}
| .s[1] = 12 # Noun
| .s[2] = 2  # Verb

| until (
  # Exit if opcode not 1 or 2
  [.s[.c]] | inside([1,2]) | not;

  # Parse current operation
  ([ .s[.c], .s[.s[.c + (1,2)]], .s[.c+3] ]) as [$op, $a, $b, $to] |

  # Do op
  if $op == 1 then
    .s[$to] = $a + $b
  else
    .s[$to] = $a * $b
  end

  # Step forward
  | .c += 4
)

# Output state in first postition
.s[0]
