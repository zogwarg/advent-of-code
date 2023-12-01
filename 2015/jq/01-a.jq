#!/usr/bin/env jq -n -R -f
{
  "(": 1,
  ")": -1
} as $up |

reduce ( inputs / "" | .[] ) as $char (0; . + $up[$char])
