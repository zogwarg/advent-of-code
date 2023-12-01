#!/usr/bin/env jq -n -R -f
[
  # Get list of digits
  inputs / "" |

  # Offset by 1 and transpose to compare each digit with next
  [. , .[1:] + .[0:1] ] | transpose[] |

  # Only return tonumber if next number is same
  if .[0] == .[1] then .[0] | tonumber else 0 end
] |

# Return sum
add
