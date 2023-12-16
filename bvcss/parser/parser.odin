package parser

import "core:fmt"
import "core:testing"

import "../tokenization"

Group_Name :: distinct string
Hex_Color :: distinct string

Color_Scheme :: struct {
	clear:      bool,
	background: Background,
	groups:     map[Group_Name]Group_Color,
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
	case tokenization.Expected_String, tokenization.Expected_End_Marker, tokenization.Expected_One_Of:
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
	case tokenization.Expected_String, tokenization.Expected_End_Marker, tokenization.Expected_Token:
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
