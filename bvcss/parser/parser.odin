package parser

import "core:fmt"
import "core:log"
import "core:strings"
import "core:testing"

import "../tokenization"

Group_Name :: distinct string
Hex_Color :: distinct string

Color_Scheme :: struct {
	clear:      bool,
	background: Background,
	highlights: map[Group_Name]Group_Color,
}

Group_Color :: union {
	Root_Color_Pair,
	Group_Name,
}

Root_Color_Pair :: struct {
	foreground: Hex_Color,
	background: Hex_Color,
}

Background :: enum (byte) {
	None,
	Dark,
	Light,
}

parse_clear :: proc(
	tokenizer: ^tokenization.Tokenizer,
) -> (
	clear: bool,
	error: tokenization.Expectation_Error,
) {
	tokenization.tokenizer_expect_exact(
		tokenizer,
		tokenization.Lower_Symbol{value = "clear"},
	) or_return

	tokenization.tokenizer_skip_any_of(tokenizer, []tokenization.Token{tokenization.Space{}})
	tokenization.tokenizer_expect(tokenizer, tokenization.Equals{}) or_return
	tokenization.tokenizer_skip_any_of(tokenizer, []tokenization.Token{tokenization.Space{}})

	t := tokenization.tokenizer_expect(tokenizer, tokenization.Boolean{}) or_return

	return t.token.(tokenization.Boolean).value, nil
}

@(test, private = "package")
test_parse_clear :: proc(t: ^testing.T) {
	tokenizer := tokenization.tokenizer_create("clear = true")
	clear, err := parse_clear(&tokenizer)
	testing.expect(t, err == nil, fmt.tprintf("unexpected error: %v", err))
	testing.expect_value(t, clear, true)

	tokenizer = tokenization.tokenizer_create("clear = false")
	clear, err = parse_clear(&tokenizer)
	testing.expect(t, err == nil, fmt.tprintf("unexpected error: %v", err))
	testing.expect_value(t, clear, false)

	tokenizer = tokenization.tokenizer_create("clear true ")
	_, err = parse_clear(&tokenizer)
	switch e in err {
	case nil:
		fmt.panicf("Expected error for missing equals, got nil")
	case tokenization.Expected_String, tokenization.Expected_End_Marker, tokenization.Expected_One_Of, tokenization.Unexpected_End_Of_File:
		fmt.panicf("Expected error for missing equals token, got %v", e)
	case tokenization.Expected_Token:
		testing.expect(
			t,
			e.expected == tokenization.Equals{},
			fmt.tprintf("Did not fail with expected token: %v", e),
		)
	}
}

parse_background :: proc(
	tokenizer: ^tokenization.Tokenizer,
) -> (
	background: Background,
	error: tokenization.Expectation_Error,
) {
	tokenization.tokenizer_expect_exact(
		tokenizer,
		tokenization.Lower_Symbol{value = "background"},
	) or_return

	tokenization.tokenizer_skip_any_of(tokenizer, []tokenization.Token{tokenization.Space{}})
	tokenization.tokenizer_expect(tokenizer, tokenization.Equals{}) or_return
	tokenization.tokenizer_skip_any_of(tokenizer, []tokenization.Token{tokenization.Space{}})

	t := tokenization.tokenizer_expect(tokenizer, tokenization.Lower_Symbol{}) or_return

	switch t.token.(tokenization.Lower_Symbol).value {
	case "dark":
		return Background.Dark, nil
	case "light":
		return Background.Light, nil
	}

	return Background.None,
		tokenization.Expected_One_Of {
			expected = []tokenization.Token {
				tokenization.Lower_Symbol{value = "dark"},
				tokenization.Lower_Symbol{value = "light"},
			},
			actual = t.token,
			location = t.location,
		}
}

@(test, private = "package")
test_parse_background :: proc(t: ^testing.T) {
	tokenizer := tokenization.tokenizer_create("background = dark")
	background, err := parse_background(&tokenizer)
	testing.expect(t, err == nil, fmt.tprintf("unexpected error: %v", err))
	testing.expect_value(t, background, Background.Dark)

	tokenizer = tokenization.tokenizer_create("background = light")
	background, err = parse_background(&tokenizer)
	testing.expect(t, err == nil, fmt.tprintf("unexpected error: %v", err))
	testing.expect_value(t, background, Background.Light)

	tokenizer = tokenization.tokenizer_create("background = none")
	_, err = parse_background(&tokenizer)
	switch e in err {
	case nil:
		fmt.panicf("Expected error for background to be either 'dark' or 'light', got nil")
	case tokenization.Expected_String, tokenization.Expected_End_Marker, tokenization.Expected_Token, tokenization.Unexpected_End_Of_File:
		fmt.panicf("Expected error for background to be either 'dark' or 'light', got %v", e)
	case tokenization.Expected_One_Of:
		if len(e.expected) != 2 {
			fmt.panicf("Expected error for missing equals token, got %v", e)
		}

		dark_found := false
		light_found := false
		for expected in e.expected {
			switch expected.(tokenization.Lower_Symbol).value {
			case "dark":
				dark_found = true
			case "light":
				light_found = true
			}
		}
		if !dark_found || !light_found {
			fmt.panicf("Expected error for missing equals token, got %v", e)
		}
	}
}

parse_highlight :: proc(
	tokenizer: ^tokenization.Tokenizer,
) -> (
	name: Group_Name,
	color: Group_Color,
	error: tokenization.Expectation_Error,
) {
	name = parse_group_name(tokenizer) or_return
	tokenization.tokenizer_expect(tokenizer, tokenization.Colon{}) or_return
	tokenization.tokenizer_skip_any_of(
		tokenizer,
		[]tokenization.Token{tokenization.Space{}, tokenization.Tab{}},
	)
	color = parse_group_color(tokenizer) or_return

	return name, color, nil
}

parse_group_name :: proc(
	tokenizer: ^tokenization.Tokenizer,
) -> (
	name: Group_Name,
	error: tokenization.Expectation_Error,
) {
	name_string := tokenization.tokenizer_read_string_until(
		tokenizer,
		[]string{":", "\n", "\r\n"},
	) or_return

	return Group_Name(name_string), nil
}

@(test, private = "package")
test_parse_group_name :: proc(t: ^testing.T) {
	context.logger = log.create_console_logger()

	DELIMITERS :: []string{":", "\n", "\r\n"}
	NAMES :: []string {
		"name",
		"Name",
		"NAME",
		"@name",
		"@name.with.sub-scope",
		"camelCaseName",
		"snake_case_name",
		"kebab-case-name",
	}
	for d in DELIMITERS {
		for n in NAMES {
			concatenated := strings.concatenate([]string{n, d})
			defer delete(concatenated)
			tokenizer := tokenization.tokenizer_create(concatenated)
			name, err := parse_group_name(&tokenizer)
			testing.expect(t, err == nil, fmt.tprintf("unexpected error: %v", err))
			testing.expect_value(t, name, Group_Name(n))
		}
	}

}

parse_group_color :: proc(
	tokenizer: ^tokenization.Tokenizer,
) -> (
	color: Group_Color,
	error: tokenization.Expectation_Error,
) {
	source_token, _, got_token := tokenization.tokenizer_next_token(tokenizer)
	if !got_token {
		return nil,
			tokenization.Unexpected_End_Of_File {
				location = tokenization.tokenizer_location(tokenizer),
			}
	}

	root_color_pair: Root_Color_Pair
	#partial switch t in source_token.token {
	case tokenization.Lower_Symbol:
		return Group_Name(t.value), nil
	case tokenization.Upper_Symbol:
		return Group_Name(t.value), nil
	case tokenization.String:
		root_color_pair.foreground = Hex_Color(t.value)
	case:
		fmt.panicf("Unexpected token for color: %v", t)
	}

	// NOTE(gonz): we should only end up here if we parsed a color string, so here we are checking for
	// possible background color values
	_, comma_error := tokenization.tokenizer_expect(tokenizer, tokenization.Comma{})
	if comma_error != nil {
		return root_color_pair, nil
	}

	tokenization.tokenizer_skip_any_of(tokenizer, []tokenization.Token{tokenization.Space{}})
	string_token := tokenization.tokenizer_expect(tokenizer, tokenization.String{}) or_return
	root_color_pair.background = Hex_Color(string_token.token.(tokenization.String).value)

	return root_color_pair, nil
}

@(test, private = "package")
test_parse_group_color :: proc(t: ^testing.T) {
	context.logger = log.create_console_logger()

	tokenizer := tokenization.tokenizer_create(`"ffffff"`)
	color, err := parse_group_color(&tokenizer)
	testing.expect(t, err == nil, fmt.tprintf("unexpected error: %v", err))
	testing.expect_value(t, color, Root_Color_Pair{foreground = Hex_Color("ffffff")})

	tokenizer = tokenization.tokenizer_create(`"ffffff", "000000"`)
	color, err = parse_group_color(&tokenizer)
	testing.expect(t, err == nil, fmt.tprintf("unexpected error: %v", err))
	testing.expect_value(
		t,
		color,
		Root_Color_Pair{foreground = Hex_Color("ffffff"), background = Hex_Color("000000")},
	)

	tokenizer = tokenization.tokenizer_create(`"fff", "dacafe"`)
	color, err = parse_group_color(&tokenizer)
	testing.expect(t, err == nil, fmt.tprintf("unexpected error: %v", err))
	testing.expect_value(
		t,
		color,
		Root_Color_Pair{foreground = Hex_Color("fff"), background = Hex_Color("dacafe")},
	)

	tokenizer = tokenization.tokenizer_create(`"fff"`)
	color, err = parse_group_color(&tokenizer)
	testing.expect(t, err == nil, fmt.tprintf("unexpected error: %v", err))
	testing.expect_value(t, color, Root_Color_Pair{foreground = Hex_Color("fff")})

	tokenizer = tokenization.tokenizer_create(`"dacafe", "421"`)
	color, err = parse_group_color(&tokenizer)
	testing.expect(t, err == nil, fmt.tprintf("unexpected error: %v", err))
	testing.expect_value(
		t,
		color,
		Root_Color_Pair{foreground = Hex_Color("dacafe"), background = Hex_Color("421")},
	)

	tokenizer = tokenization.tokenizer_create(`"ffffff",`)
	_, err = parse_group_color(&tokenizer)
	expected_token, is_expected_token_error := err.(tokenization.Expected_Token)
	testing.expect(
		t,
		is_expected_token_error,
		fmt.tprintf("Expected token expectation error, got: %v", err),
	)
	_, is_string_expectation := expected_token.expected.(tokenization.String)
	testing.expect(
		t,
		is_string_expectation,
		fmt.tprintf("Expected string expectation, got: %v", expected_token.expected),
	)
}
