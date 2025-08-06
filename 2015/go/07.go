///usr/bin/env go run $0 $@ ; exit
package main

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"

	"github.com/zogwarg/advent-of-code/utils/go"
)

type wire struct {
	op   string
	args []string
	out  string
}

func main() {
	input := strings.Trim(string(utils.GetInputBytes()), "\n")
	wires := make(map[string]wire)
	op_re := regexp.MustCompile("[A-Z]+")
	args_re := regexp.MustCompile("[a-z0-9]+")

	for _, line := range strings.Split(input, "\n") {
		op := op_re.FindAllString(line, 1)
		items := args_re.FindAllString(line, 3)
		if len(op) > 0 {
			wires[items[len(items)-1]] = wire{op[0], items[:len(items)-1], items[len(items)-1]}
		} else {
			wires[items[len(items)-1]] = wire{"ID", items[:len(items)-1], items[len(items)-1]}
		}
	}

	a := compute(wires, "a", make(map[string]int))
	wires["b"] = wire{"ID", []string{strconv.Itoa(a)}, "b"}
	b := compute(wires, "a", make(map[string]int))

	fmt.Printf("Part A: %d\n", a)
	fmt.Printf("Part B: %d\n", b)
}

func compute(wires map[string]wire, out string, seen map[string]int) int {
	if val_seen, ok := seen[out]; ok {
		return val_seen
	}

	if int_val, err := strconv.Atoi(out); err == nil {
		return int_val
	}

	wire := wires[out]

	switch wires[out].op {
	case "AND":
		seen[wire.out] = compute(wires, wire.args[0], seen) & compute(wires, wire.args[1], seen)
	case "OR":
		seen[wire.out] = compute(wires, wire.args[0], seen) | compute(wires, wire.args[1], seen)
	case "RSHIFT":
		seen[wire.out] = compute(wires, wire.args[0], seen) >> compute(wires, wire.args[1], seen)
	case "LSHIFT":
		seen[wire.out] = compute(wires, wire.args[0], seen) << compute(wires, wire.args[1], seen)
	case "NOT":
		seen[wire.out] = ^compute(wires, wire.args[0], seen)
	case "ID":
		seen[wire.out] = compute(wires, wire.args[0], seen)
	}

	return seen[wire.out]
}
