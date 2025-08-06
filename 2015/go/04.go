///usr/bin/env go run $0 $@ ; exit
package main

import (
	"crypto/md5"
	"fmt"
	"strings"

	"github.com/zogwarg/advent-of-code/utils/go"
)

func main() {
	input := strings.Trim(string(utils.GetInputBytes()), "\n")
	i, hash := 1, md5.Sum([]byte(input))

	for hash[0] != 0 || hash[1] != 0 || hash[2] > 15 {
		i++
		hash = md5.Sum([]byte(fmt.Sprintf("%s%d", input, i)))
	}

	a := i

	for hash[0] != 0 || hash[1] != 0 || hash[2] != 0 {
		i++
		hash = md5.Sum([]byte(fmt.Sprintf("%s%d", input, i)))
	}

	fmt.Printf("Part A: %d\n", a)
	fmt.Printf("Part B: %d\n", i)
}
