#!/usr/bin/env bash

_advent-get-description() {
  year=$(cat year.txt)
  day=$(cat day.txt)
  curl -H "Cookie: session=$(cat session.txt)" -s https://adventofcode.com/${year}/day/${day} \
  | jq -srR 'match("<main>.+</main>";"gm").string
  | gsub("(?<=a href=\")(?<a>[^\"]+)\">(?<l>.+?)(?=</a)"; "\(.a)\">\(.l) [\(.a)]")
  | gsub("(?<=<span title=\")(?<t>[^\"]+)\">(?<s>.+?)(?=</span)";"\(.t)\">\(.s) [\(.t)]")' \
  | lynx -stdin -dump -nolist > description.txt
}

advent-get-input() {
  year=${1:-$(date +'%Y')}
  day=${2:-$(date +'%d' | jq)}
  curl -H "Cookie: session=$(cat session.txt)" -s https://adventofcode.com/${year}/day/${day}/input > input.txt
  printf $year > year.txt
  printf $day > day.txt
  _advent-get-description
}

advent-part-a() {
  cat > a.jq <<TERM
#!/usr/bin/env jq -n -R -f

[
  inputs
]
TERM

  chmod +x a.jq
  subl a.jq
}

advent-part-b() {
  cp a.jq b.jq
  subl b.jq
}

advent-submit-a() {
  year=$(cat year.txt)
  day=$(cat day.txt)
  curl -s https://adventofcode.com/${year}/day/${day}/answer \
    -H "Cookie: session=$(cat session.txt)" \
    -H 'content-type: application/x-www-form-urlencoded' \
    -d "level=1&answer=$(./a.jq input.txt | jq -rR '@uri')" \
    | jq -srR 'match("<main>.+</main>";"gm").string' | lynx -stdin -dump -nolist
}

advent-submit-b() {
  year=$(cat year.txt)
  day=$(cat day.txt)
  curl -s https://adventofcode.com/${year}/day/${day}/answer \
    -H "Cookie: session=$(cat session.txt)" \
    -H 'content-type: application/x-www-form-urlencoded' \
    -d "level=2&answer=$(./b.jq input.txt | jq -rR '@uri')" \
    | jq -srR 'match("<main>.+</main>";"gm").string' | lynx -stdin -dump -nolist
}

advent-write-day() {
  year=$(cat year.txt)
  day=$(cat day.txt | xargs printf "%02d")
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
    [inputs | [scan("\\d+")]] | first(
      group_by(.[0]) | map(sort_by(.[1]) | reverse[0]
    ) | .[] | select(.[1] != "25")) | .[0], (.[1] | tonumber + 101 | tostring[-2:])')
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
