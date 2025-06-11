#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

{
  "(": 1,
  ")": -1
} as $up |

reduce ( inputs / "" | .[] ) as $char (0; . + $up[$char])
