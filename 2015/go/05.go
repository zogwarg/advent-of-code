///usr/bin/env go run $0 $@ ; exit
package main

import (
	"fmt"
	"regexp"
	"slices"
	"strings"

	"github.com/zogwarg/advent-of-code/utils/go"
)

const (
	vowelsExpr = "[aiueo]"
	forbidExpr = "ab|cd|pq|xy"
)

// Manual "Backtracking" expressions //
func doubleExpr() (expr string) {
	for l := 'a'; l <= 'z'; l++ {
		expr += fmt.Sprintf("|%c%c", l, l)
	}
	return expr[1:]
}
func pairs2Expr() (expr string) {
	for l := 'a'; l <= 'z'; l++ {
		for m := 'a'; m <= 'z'; m++ {
			expr += fmt.Sprintf("|%c%c.*%c%c", l, m, l, m)
		}
	}
	return expr[1:]
}
func burgerExpr() (expr string) {
	for l := 'a'; l <= 'z'; l++ {
		expr += fmt.Sprintf("|%c.%c", l, l)
	}
	return expr[1:]
}

func main() {
	input, niceA, niceB := string(utils.GetInputBytes()), 0, 0

	vowels := regexp.MustCompile(vowelsExpr)
	forbid := regexp.MustCompile(forbidExpr)
	double := regexp.MustCompile(doubleExpr())
	pairs2 := regexp.MustCompile(pairs2Expr())
	burger := regexp.MustCompile(burgerExpr())

	for _, line := range strings.Split(input, "\n") {
		v := vowels.FindAllString(line, -1)
		slices.Sort(v)
		slices.Compact(v)

		if len(v) > 2 && double.MatchString(line) && !forbid.MatchString(line) {
			niceA++
		}

		if pairs2.MatchString(line) && burger.MatchString(line) {
			niceB++
		}
	}

	fmt.Printf("Part A: %d\n", niceA)
	fmt.Printf("Part B: %d\n", niceB)
}
