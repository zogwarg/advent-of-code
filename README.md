# Advent-of-code

My completion of the advent of code challenge, using jq (and maybe other languages in the future).
Started in 2023, but trying to implement past years as well.
The main purpose is fun, not necessarily correctness or readability.

```bash
# Running a particular day can be done directly with a given day's input.txt
# For most days (but not all) should also work with example.txt files.
./2015/jq/01-a.jq input.txt

# Convenience bash functions are included, `. functions.sh`
# Requires a `session.txt` file, with session cookie.

advent-get-input        # Get day of month for current year.
advent-get-input 2021 1 # Gets input for a specific year, for specific year.
                        # Autocompletes to latest day of earliest incomplete year.

_advent-get-description # Gets description to `description.txt` file for
                        # For last input.txt, called by advent-get-input
                        # Need to call it again for `part 2`
                        # Requires `jq` `lynx`

advent-part-a # Creates a 'part 1' script from template to `a.jq` file.
advent-part-b # Creates a 'part 2' script by copying `a.jq` to 'b.jq'

advent-submit-a # Runs and submits part 1 to AoC website.
advent-submit-b # Runs and submits part 2 to AoC website.

advent-write-day # Once day is complete, copies solution to /<year>/jq/<day>-<a|b>.jq
```
