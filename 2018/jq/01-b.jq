#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

{
  num: [inputs | tonumber], # input
  cur: 0,                   # current frequency
  break: false,             # break point
  neg: [], pos: [],         # "hash" of visited frequencies
  i: 0                      # cursor for input (loops % length)
} | .l = (.num | length) |  # length of input

until (.break;
  # "hash" functions for visited frequencies
  def has_seen($neg; $pos; $cur): if $cur < 0 then $neg[-$cur] else $pos[$cur] end;
  def update_seen($cur): (if $cur < 0 then .neg[-$cur] else .pos[$cur] end) = true;

  if has_seen(.neg; .pos; .cur) then
    # If seen, break
    .break = true
  else
    # Else update seen + current frequency
    update_seen(.cur) |
    .cur = (.cur + .num[.i % .l] ) |
    .i += 1
  end
) | .cur
