#!/usr/bin/env jq -f

# Literally made for JQ,  it feels almost like an unfair advantage!
[ del(..|objects|select([.[] == "red"]|any)) | .. | numbers ] | add
