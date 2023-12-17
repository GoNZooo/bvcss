package bvcss

import "core:fmt"
import "core:os"

import "./parser"

main :: proc() {
	if len(os.args) < 2 {
		fmt.printf("Usage: bvcss <bvcss file>")

		os.exit(1)
	}

	filename := os.args[1]

	if !os.exists(filename) {
		fmt.printf("File does not exist: %s", filename)

		os.exit(1)
	}

	file_data, read_ok := os.read_entire_file_from_filename(filename)
	if !read_ok {
		fmt.printf("Could not read file: %s", filename)

		os.exit(1)
	}

	color_scheme, parse_error := parser.parse_file(data = string(file_data), filename = filename)
	if parse_error != nil {
		fmt.printf("Error parsing file: %v", parse_error)

		os.exit(1)
	}

	output, output_error := parser.output_color_scheme(color_scheme)
	if output_error != nil {
		fmt.printf("Error outputting color scheme: %s", output_error)

		os.exit(1)
	}

	fmt.print(output)
}
