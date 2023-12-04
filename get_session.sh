#!/usr/bin/env bash

# Get session from chrome cookies on mac, using hombrew openssl
if [[ -n $CHROME_PWD ]]; then
sqlite3 ~/Library/Application\ Support/Google/Chrome/Default/Cookies \
  'SELECT encrypted_value FROM cookies where host_key = ".adventofcode.com" and name = "session"' \
  | xxd -ps | tr -d '\n' \
  | jq -Rrs '.[6:-2]' | xxd -r -ps \
  | openssl enc -d -aes-128-cbc \
      -iv 20202020202020202020202020202020 -K $(
        openssl kdf -keylen 16 -kdfopt iter:1003 -kdfopt salt:saltysalt -kdfopt pass:${CHROME_PWD} PBKDF2 | tr -d :
      ) > "$(dirname -- "${BASH_SOURCE[0]}")/session.txt"
else

echo "CHROME_PWD should be set!" >&2
exit 1

fi
