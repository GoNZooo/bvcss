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
}

parse_background :: proc(
	tokenizer: ^tokenization.Tokenizer,
) -> (
	background: Background,
	error: tokenization.Expectation_Error,
) {
	return
}
