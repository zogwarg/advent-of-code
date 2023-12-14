#!/usr/bin/env jq -n -R -f

# Balanced parenthesis pairs, and completion score
{ ")":"(", ">":"<", "]":"[", "}":"{" } as $pairs |
{ "(": 1,  "<": 4,  "[": 2,  "{": 3  } as $score |

# Simple state automaton for bracket matching
reduce inputs as $line ({};
  reduce ($line / "" | .[]) as $char (.s = []| del(.o);
    if .o then
      . # If illegal closing bracket then skip
    elif $pairs[$char] | not then
      .s += [$char]
    elif $pairs[$char] != .s[-1] then
      .o = $char
    else
      .s |= .[:-1]
    end
  )
  |
  if .o then . else
    # Pop stack, and compute score for the
    # auto-completed brackets
    .scores += [reduce ( .s | reverse[] ) as $char (0;
      . * 5 + $score[$char]
    )]
  end
)

# Output median comp score
| .scores | sort[length/2]
