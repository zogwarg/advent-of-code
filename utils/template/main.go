///usr/bin/env go run $0 $@ ; exit
package main

import (
	"fmt"
	"github.com/zogwarg/advent-of-code/utils/go"
)

func main() {
	input := string(utils.GetInputBytes())

	fmt.Printf("Part A: %d\n", len(input))
	fmt.Printf("Part B: %d\n", 0)
}
