#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce(
  # Annihilitate !. pairs, clean uneeded "," and <.+> seqs
  inputs | gsub("!.|,";"") | gsub("<[^>]*>";"") / "" | .[]
) as $p (
  {d:0,s:0}; # Simple state machine with: .d <=> "{" stack.
  if  $p == "{" then  .d += 1 | .s += .d  else .d -= 1  end
  # Output score
) | .s
