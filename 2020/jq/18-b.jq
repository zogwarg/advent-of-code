#!/usr/bin/env jq -n -R -f

[
    inputs          # Make parentheses groups
  | gsub("\\(";"[") | gsub("\\)";"]")
  | gsub(" ";",")   | gsub("(?<op>[+*])";"\"\(.op)\"")
  | "[\(.)]"        | fromjson

  | walk(if type == "array" then
      reduce (
        reduce indices("+")[] as $i ([]; if .[-1][-1] != ($i-1)
          then      .     + [[$i-1,$i,($i+1)]]
          else .[-1][-1:] =  [$i-1,$i,($i+1)]  end
        ) | .[]
      ) as $f (.; .[$f[0]] = [ .[$f[]] ] | .[$f[1:][]] = null )
    end) # # Group contiguous "+" sequences in new parentheses

  | del(.. | nulls) | debug(.) # Print PAM tree (not PEMDAS)

  # Operate!
  | walk(if type == "array" then
      reduce (
        .[1:] as $in | range(0;$in|length;2) | $in[.:.+2]
      ) as [$op, $b] (.[0];
        if $op == "+" then . + $b else . * $b end
      )
    end)
]

| add # Output sum of all lines
