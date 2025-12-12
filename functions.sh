#!/usr/bin/env bash

_advent-get-description() {
  local year=$(cat year.txt)
  local day=$(cat day.txt)

  curl \
    -H "Cookie: session=$(cat session.txt)" \
    -s https://adventofcode.com/${year}/day/${day} \
  | jq -srR 'match("<main>.+</main>";"gm").string
  | gsub(
      "(?<=a href=\")(?<a>[^\"]+)\">(?<l>.+?)(?=</a)";
      "\(.a)\">\(.l) [\(.a)]"
    )
  | gsub(
      "(?<=<span title=\")(?<t>[^\"]+)\">(?<s>.+?)(?=</span)";
      "\(.t)\">\(.s) [\(.t)]"
    )' \
  | lynx -stdin -dump -nolist > description.txt
}

advent-get-input() {
  local year=${1:-$(date +'%Y')}
  local day=${2:-$(date +'%d' | jq)}

  curl \
    -H "Cookie: session=$(cat session.txt)" \
    -s https://adventofcode.com/${year}/day/${day}/input > input.txt

  printf $year > year.txt
  printf $day > day.txt
  _advent-get-description
}

advent-part-a() {
  cat > a.jq <<'TERM'
#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  inputs
]
TERM

  chmod +x a.jq
  subl a.jq
}

advent-part-b() {
  _advent-get-description
  cp a.jq b.jq
  subl b.jq
}

advent-submit-a() {
  local year=$(cat year.txt)
  local day=$(cat day.txt)

  curl \
    -s https://adventofcode.com/${year}/day/${day}/answer \
    -H "Cookie: session=$(cat session.txt)" \
    -H 'content-type: application/x-www-form-urlencoded' \
    -d "level=1&answer=$(./a.jq input.txt | jq -rR '@uri')" \
    | jq -srR 'match("<main>.+</main>";"gm").string' | lynx -stdin -dump -nolist
}

advent-submit-b() {
  local year=$(cat year.txt)
  local day=$(cat day.txt)

  curl \
    -s https://adventofcode.com/${year}/day/${day}/answer \
    -H "Cookie: session=$(cat session.txt)" \
    -H 'content-type: application/x-www-form-urlencoded' \
    -d "level=2&answer=$(./b.jq input.txt | jq -rR '@uri')" \
    | jq -srR 'match("<main>.+</main>";"gm").string' | lynx -stdin -dump -nolist
}

advent-write-day() {
  local year=$(cat year.txt)
  local day=$(cat day.txt | xargs printf "%02d")

  if [[ ! $day = "25" ]]; then
    mv a.jq ${year}/jq/${day}-a.jq
    mv b.jq ${year}/jq/${day}-b.jq
  else
    mv a.jq ${year}/jq/${day}.jq
  fi
}

_advent_complete()
{
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  NEXT_DAY=($(find ./20* -name '*.jq' | jq -rR '
    [ inputs | [scan("\\d+")] ]
    | first(
        group_by(.[0])
        | map(sort_by(.[1]) | reverse[0] )
        | .[] | select(.[1] != "25")
      )
    | .[0], (.[1] | tonumber + 1)')
  )

  if [[ "${prev}" == "advent-get-input" ]]; then
    COMPREPLY=($(compgen -W "${NEXT_DAY[0]}" -- $cur))
    return 0
  fi

  if [[ "${prev}" == "${NEXT_DAY[0]}" ]]; then
    COMPREPLY=($(compgen -W "${NEXT_DAY[1]}" -- $cur))
    return 0
  fi
}

complete -F _advent_complete advent-get-input

# Local running utilities, including non commited inputs and descriptions
if [[ -d "$PWD/.tom_safe" ]] ; then
  # Used to override jq version in used,
  # Binaries or symlinks should be included at ~/.tom_safe/$JQ_VERSION
  JQ_VERSION=${JQ_VERSION:-local}
  if [[ -f "$PWD/.tom_safe/$JQ_VERSION/jq" ]] ; then
    PATH="$PWD/.tom_safe/$JQ_VERSION:$PATH"
  fi

  x-advent-copy()
  {
    local year=$(cat year.txt)
    local day=$(cat day.txt | xargs printf "%02d")
    cp input.txt ./.tom_safe/${year}-${day}.input.txt
    cp description.txt ./.tom_safe/${year}-${day}.description.txt
  }

  x-advent-jq()
  {
    local YEAR=$1
    local PART=$2

    if [[ $PART =~ ^[0-9]{2}$ ]] && [[ $PART != "25" ]] ; then
      echo "${YEAR}/${PART}:"; echo
      if [[ -f ./${YEAR}/jq/${PART}-a.jq ]]; then
        time \
          ./${YEAR}/jq/${PART}-a.jq "${@:3}" \
          ./.tom_safe/${YEAR}-${PART/-[ab]/}.input.txt
        echo
      fi
      if [[ -f ./${YEAR}/jq/${PART}-b.jq ]]; then
        time \
          ./${YEAR}/jq/${PART}-b.jq "${@:3}" \
          ./.tom_safe/${YEAR}-${PART/-[ab]/}.input.txt
        echo
      fi
      cat ./.tom_safe/${YEAR}-${PART/-[ab]/}.description.txt \
        | grep -e 'answer was' | sed -Ee 's/^ +//'
      echo
    elif [[ $PART =~ ^[0-9]{2}-a$ ]] || [[ $PART == "25" ]] ; then
      echo "${YEAR}/${PART}:"; echo
      time \
        ./${YEAR}/jq/${PART}.jq "${@:3}" \
        ./.tom_safe/${YEAR}-${PART/-[ab]/}.input.txt
      echo
      cat ./.tom_safe/${YEAR}-${PART/-[ab]/}.description.txt \
        | grep -e 'answer was' | sed -Ee 's/^ +//' | head -n 1
      echo
    elif [[ $PART =~ ^[0-9]{2}-b$ ]] ; then
      echo "${YEAR}/${PART}:"; echo
      time \
        ./${YEAR}/jq/${PART}.jq "${@:3}" \
        ./.tom_safe/${YEAR}-${PART/-[ab]/}.input.txt
      echo
      cat ./.tom_safe/${YEAR}-${PART/-[ab]/}.description.txt \
        | grep -e 'answer was' | sed -Ee 's/^ +//' | tail -n 1
      echo
    else
      echo "Unexpected PART: $PART"
    fi
  }

  x-advent-go()
  {
    local YEAR=$1
    local DAY=$2

    echo "${YEAR}/${DAY}:"; echo
    time ./${YEAR}/go/${DAY}.go ./.tom_safe/${YEAR}-${DAY}.input.txt
    echo
    cat ./.tom_safe/${YEAR}-${DAY}.description.txt \
      | grep -e 'answer was' | sed -Ee 's/^ +//'
  }
fi
