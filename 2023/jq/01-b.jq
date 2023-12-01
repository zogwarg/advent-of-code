#!/usr/bin/env jq -n -R -f

# Define string to num value map
{
  "one":   1,  "1": 1,
  "two":   2,  "2": 2,
  "three": 3,  "3": 3,
  "four":  4,  "4": 4,
  "five":  5,  "5": 5,
  "six":   6,  "6": 6,
  "seven": 7,  "7": 7,
  "eight": 8,  "8": 8,
  "nine":  9,  "9": 9
} as $to_num |

# Get and reduce every "pretty" line
reduce inputs as $line (
  0;
  . + (
    $line |
    # Try two capture two numbers
    capture("(^.*?(?<f>(one|two|three|four|five|six|seven|eight|nine|[1-9])).*(?<l>(one|two|three|four|five|six|seven|eight|nine|[1-9])).*?$)?") |
    # If no capture, get one number twice
    if .f == "" then $line | capture("^.*?(?<f>(one|two|three|four|five|six|seven|eight|nine|[1-9]))") | .l = .f else . end |
    # Add extracted number
    $to_num[.f] * 10 + $to_num[.l]
  )
)
