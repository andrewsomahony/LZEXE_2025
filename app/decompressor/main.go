package main

import (
	"log"

	// "github.com/andrewsomahony/LZEXE_2025/decompressor/routine"
	peparser "github.com/saferwall/pe"
)

func main() {
	// Temporary filename for now
	test_file_path := "test/HELLO.EXE"

	parser, _error := peparser.New(test_file_path, &peparser.Options{})
	if nil != _error {
		log.Fatalf("Error opening PE file: %v", _error)
	} else {
		_error = parser.Parse()

		if (nil != _error) {
			log.Fatalf("Error parsing PE file: %v", _error)
		} else {
			log.Printf("PE file parsed successfully")
		}
	}
}
