#!/usr/bin/env jq -n -R -f

# Get first row with wall padding
[["w"] + ( inputs / "" ) + ["w"]] |

# Get next 399999 rows
until (length | debug == 400000;
  .[-1] as $in |
  . + [
    [
      "w",
      (
        range(0;$in|length-2) | $in[.:.+3]
        | join("") | sub("w";".")
        | {
            "^^.": "^",
            ".^^": "^",
            "..^": "^",
            "^..": "^"
          }[.] // "."
      ),
      "w"
    ]
  ]
)

# Count total safe spaces
| add | [ .[] | select(. == ".") ] | length
