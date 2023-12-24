#!/usr/bin/env jq -n -R -f

# Greatest Common Divisor function:
def GCD($a; $b): if $b == 0 then $a else GCD($b; $a % $b) end;

# Determinant of an order 2 matrix
def det2($mat):
  $mat[0][0] * $mat[1][1] - $mat[0][1] * $mat[1][0]
;

# Recursive determinant of N>2 order matrix
def det($mat):
  if ($mat|length) == 2 then
    det2($mat)
  else
    reduce range($mat|length) as $i (0;
      if $i % 2 == 0 then
        . + $mat[0][$i] * det($mat[1:]|map(.[:$i] + .[$i+1:]))
      else
        . - $mat[0][$i] * det($mat[1:]|map(.[:$i] + .[$i+1:]))
      end
    )
  end
;

[
  inputs               # Parse Inputs:
  | [ scan("-?\\d+") ] # Extract numbers
  | map(tonumber)      # Convert to numeric type
  | .                  # All x, y, z, dx, dy, dz
] | . as $lines |

# The rock collides with X coordinate (and separately Y,Z)
# x(a) + t(a) * dx(a) = X + t(a) * DX
# x(b) + t(b) * dx(b) = X + t(b) * DX
# [...]
#
# => x(a) * t(a) (dx(a) - DX) = X
# => X ≡ x(i) mod(dx(i) - DX)
# => given dx(i) = dx(j) -> x(i) ≡ x(j) mod(dx(i) - DX)
# => given dx(i) = dx(j) -> x(i) - x(j) is divisible by dx(i) - DX
#
# We can use this to reduce DX, DY and DZ

# Gets all candidate DX for a group sharing the same dx(i)
def candidate_DX($pos;$group):
  $lines | group_by(.[$pos+3]) | sort_by(-length) | .[$group] |
  .[0][$pos+3] as $dx |
  reduce (
    [.[][$pos]] | combinations(2) | select(.[0] < .[1]) | .[1] - .[0]
  ) as $d (.[0][$pos]-.[1][$pos]; GCD(.;$d))
  | if . > 50000 then "High GCD: \(.)" | halt_error end
  | ( [ range(.+1) as $i | GCD(.;$i) ] | unique ) as $minus
  | [ $dx | . += ($minus[],-$minus[])]
;

# Reduce DX, DY, DZ to 1 by successively intersecting
# The candidates from groups with the same dx(i)
{
  DX: candidate_DX(0;0),
  DY: candidate_DX(1;0),
  DZ: candidate_DX(2;0),
  i: 1,
} |
until (
  (.DX|length) == 1 and (.DY|length) == 1 and (.DZ|length == 1);
  .DX -= (.DX - candidate_DX(0;.i)) |
  .DY -= (.DY - candidate_DX(1;.i)) |
  .DZ -= (.DZ - candidate_DX(2;.i)) |
  .i += 1
) | del(.i) | .[] |= .[0] | . as {$DX, $DY, $DZ} |

# We have a system of equations , with 5 unknowns
#
# xa + ta * dxa = X + ta * DX  │ +2 unknowns ta, X
# ya + ta * dya = Y + ta * DY  │ +1 unknowns Y
# za + ta * dza = Z + ta * DZ  │ +1 unknowns Z
# xb + tb * dxb = X + tb * DX  │ +1 unknowns tb
# yb + tb * dyb = Y + tb * DY  │ +0 unknowns
#
# Solving with degree five matrix
# ┌                       ┐   ┌    ┐
# │ 1  0  0 DX-dxa   0    │   │ xa │
# │ 0  1  0 DY-dya   0    │   │ ya │
# │ 0  0  1 DZ-dza   0    │ = │ za │
# │ 1  0  0   0    DX-dxb │   │ xb │
# │ 0  1  0   0    DY-dyb │   │ zb │
# └                       ┘   └    ┘

$lines[0] as [$xa,$ya,$za,$dxa,$dya,$dza] |
$lines[1] as [$xb,$yb,$zb,$dxb,$dyb,$dzb] |

det([
  [1, 0, 0, $DX - $dxa, 0],
  [0, 1, 0, $DY - $dya, 0],
  [0, 0, 1, $DZ - $dza, 0],
  [1, 0, 0, 0, $DX - $dxb],
  [0, 1, 0, 0, $DY - $dyb]
]) as $det |

# Rounding because of precision loss
(det([
  [$xa, 0, 0, $DX - $dxa, 0],
  [$ya, 1, 0, $DY - $dya, 0],
  [$za, 0, 1, $DZ - $dza, 0],
  [$xb, 0, 0, 0, $DX - $dxb],
  [$yb, 1, 0, 0, $DY - $dyb]
])/$det|round) as $X |

(det([
  [1, $xa, 0, $DX - $dxa, 0],
  [0, $ya, 0, $DY - $dya, 0],
  [0, $za, 1, $DZ - $dza, 0],
  [1, $xb, 0, 0, $DX - $dxb],
  [0, $yb, 0, 0, $DY - $dyb]
])/$det|round) as $Y |

(det([
  [1, 0, $xa, $DX - $dxa, 0],
  [0, 1, $ya, $DY - $dya, 0],
  [0, 0, $za, $DZ - $dza, 0],
  [1, 0, $xb, 0, $DX - $dxb],
  [0, 1, $yb, 0, $DY - $dyb]
])/$det|round) as $Z |

# Output to stderr for satisfaction
debug({$X,$Y,$Z,$DX,$DY,$DZ}) |

# Outputting sum of intial rock coordinates
$X + $Y + $Z
