#!/bin/sh
# \
exec jq -n -f "$0" "$@"

# The Jospehus problem, across-the-circle elf edition

# Too slow of an implementation in JQ for our input
def winner($n):
  [ range(1;$n+1) ]
  | until (length == 1;
    del(.[length/2]) | .[1:] + [.[0]]
  )
  | .[0]
;

# It appears the pattern is
#   N  = 3^a + l
# W(N) = N             if l == 0
# W(N) = l             if l <= N/2
# W(N) = 2*N - 3^(a+1) if l >  N/2

def W($n):
  (($n|log)/(3|log)|floor) as $a |
  ($n-pow(3;$a)) as $l |
  if $l == 0 then
    $n
  elif 2 * $l > $n then
    2 * $n - pow(3;$a+1)
  else
    $l
  end
;

# Validating for first 250 numbers
if any(range(1;251); winner(.) != W(.)) then
  "Pattern is wrong" | halt_error
else
  W(inputs)
end
