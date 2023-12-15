#!/usr/bin/env jq -n -R -f

[
  foreach ( # For each input produce stream of dir U2 -> U, U
    inputs / " " | .[0] as $dir | range(.[1]|tonumber) | $dir
  ) as $dir (
    {HT:[0,0],T:[0,0]}; # State HT = H-T vector, T = position

    # For each move update relative HT, and absolute tail pos
    if .HT == [ 0, 0 ] then
      .HT = {"U":[ 0, 1 ], "D":[ 0,-1 ], "L":[-1, 0 ], "R":[ 1, 0 ]}[$dir]
    elif .HT == [ 0, 1 ] then
      .HT = {"U":[ 0, 1 ], "D":[ 0, 0 ], "L":[-1, 1 ], "R":[ 1, 1 ]}[$dir] |
      .T[1] += {"U": 1}[$dir] // 0
    elif .HT == [ 0,-1 ] then
      .HT = {"U":[ 0, 0 ], "D":[ 0,-1 ], "L":[-1,-1 ], "R":[ 1,-1 ]}[$dir] |
      .T[1] += {"D":-1}[$dir] // 0
    elif .HT == [-1, 0 ] then
      .HT = {"U":[-1, 1 ], "D":[-1,-1 ], "L":[-1, 0 ], "R":[ 0, 0 ]}[$dir] |
      .T[0] += {"L":-1}[$dir] // 0
    elif .HT == [ 1, 0 ] then
      .HT = {"U":[ 1, 1 ], "D":[ 1,-1 ], "L":[ 0, 0 ], "R":[ 1, 0 ]}[$dir] |
      .T[0] += {"R": 1}[$dir] // 0
    elif .HT == [ 1, 1 ] then
      .HT = {"U":[ 0, 1 ], "D":[ 1, 0 ], "L":[ 0, 1 ], "R":[ 1, 0 ]}[$dir] |
      .T[0] += {"U": 1, "R": 1}[$dir] // 0 |
      .T[1] += {"U": 1, "R": 1}[$dir] // 0
    elif .HT == [ 1,-1 ] then
      .HT = {"U":[ 1, 0 ], "D":[ 0,-1 ], "L":[ 0,-1 ], "R":[ 1, 0 ]}[$dir] |
      .T[0] += {"D": 1, "R": 1}[$dir] // 0 |
      .T[1] += {"D":-1, "R":-1}[$dir] // 0
    elif .HT == [-1, 1 ] then
      .HT = {"U":[ 0, 1 ], "D":[-1, 0 ], "L":[-1, 0 ], "R":[ 0, 1 ]}[$dir] |
      .T[0] += {"U":-1, "L":-1}[$dir] // 0 |
      .T[1] += {"U": 1, "L": 1}[$dir] // 0
    elif .HT == [-1,-1 ] then
      .HT = {"U":[-1, 0 ], "D":[ 0,-1 ], "L":[-1, 0 ], "R":[ 0,-1 ]}[$dir] |
      .T[0] += {"D":-1, "L":-1}[$dir] // 0 |
      .T[1] += {"D":-1, "L":-1}[$dir] // 0
    else "Unexpected HT: \(.HT)" | halt_error end

    ; .T # Extract tail position as new stream
  )      # Count unique visited tail positions
] | unique | length
