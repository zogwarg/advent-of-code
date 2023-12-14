#!/usr/bin/env jq -n -R -f

# Balanced parenthesis pairs
{ ")":"(", ">":"<", "]":"[", "}":"{" } as $pairs |

# State automaton for finding illegal closing character
reduce inputs as $line ({};
  reduce ($line / "" | .[]) as $char (.s = []| del(.o);
    if .o then
      .
    elif $pairs[$char] | not then
      .s += [$char]
    elif $pairs[$char] != .s[-1] then
      .o = $char | .[$char] += 1
    else
      .s |= .[:-1]
    end
  )
)

#File score sum, are we on the syntax checker leaderboards?
| 3 * .[")"] + 57 * .["]"] + 1197 * .["}"] + 25137 * .[">"]
