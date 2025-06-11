#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce(
  inputs
  | [
      ({on:true, off: false}[scan("on|off")]),
           (scan("-?\\d+")|tonumber)
    ]
  | select(all(.[1:][]|abs;. <= 50))
) as [$s,$x1,$x2,$y1,$y2,$z1,$z2] (.;
  .["\( # Lazy bruteforce for part 1
    range($x1;$x2+1) as $x |
    range($y1;$y2+1) as $y |
    range($z1;$z2+1) as $z |
    [$x,$y,$z]
  )"] = $s
)

| [ .[] | select(.) ] | length
