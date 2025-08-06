package utils

import (
	"io"
	"io/ioutil"
	"os"
)

func GetInputBytes() []byte {
	if len(os.Args) > 1 {
		if _, err := os.Stat(os.Args[1]); err == nil {
			if data, err := ioutil.ReadFile(os.Args[1]); err == nil {
				return data
			}
		}
	}
	if stat, _ := os.Stdin.Stat(); (stat.Mode() & os.ModeCharDevice) != 0 {
		return nil
	}
	if data, err := io.ReadAll(os.Stdin); err == nil {
		return data
	}
	return nil
}
