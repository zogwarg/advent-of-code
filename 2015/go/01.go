///usr/bin/env go run $0 $@ ; exit
package main

import (
	"fmt"
	"github.com/zogwarg/advent-of-code/utils/go"
)

func main() {
	level, sub := 0, false
	for i, char := range utils.GetInputBytes() {
		switch char {
		case '(':
			level++
		case ')':
			level--
			if level < 0 && !sub {
				sub = true
				defer fmt.Printf("Part B: %d\n", i+1)
			}
		}
	}
	fmt.Printf("Part A: %d\n", level)
}
