#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

inputs | [ scan("\\d+")|tonumber ] as [ $row, $col ] |

# N(row, col) = N(row,0) + (row + 1) + ... + ( row + col - 1 )
#             = N(row,0) + col*(col-1)/2 + (col-1)*row
#             = 1 + row*(row-1)/2 + col*(col-1)/2 + (col-1)*row

def N($row;$col):
  1 + $row*($row-1)/2 + $col*($col-1)/2 + ($col-1)*$row
;

reduce range(1;N($row;$col)) as $_ (20151125; . * 252533 % 33554393)
