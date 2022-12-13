extends Reference

const Tokens = preload("res://addons/GViNT/Core/Translator/Tokenizer/Tokens.gd")
const Chars = preload("res://addons/GViNT/Core/Translator/Characters.gd")

const ALWAYS_SINGLE_CHARACTER_TOKENS = (
	Chars.WRAPPING_CHARS
	+ Chars.LINEBREAK
	+ Chars.DOT
	+ Chars.COMMA
	+ Chars.COLON
)

var source_filename: String
var source_line: int

var type: String = ""
var text: String = ""

var is_valid_identifier: bool = false

var is_regular_integer: bool = false
var is_hex_integer: bool = false
var is_binary_integer: bool = false

var is_regular_float: bool = false
var is_scientific_notation_float: bool = false

var is_operator: bool = false

var is_inline_text: bool = false
var is_keyword: bool = false

func start(character: String):
	assert(len(character) == 1)
	assert(not text)
	if (character == Chars.UNDERSCORE) or (character in Chars.LETTERS):
		is_valid_identifier = true
	elif character in Chars.DIGITS:
		is_regular_integer = true
		type = Tokens.INT
	elif character in Chars.OPERATOR_CHARS:
		is_operator = true
	text = character



func add_character(character: String):
	assert(len(character) == 1)
	assert(len(text) >= 1)
	if is_valid_identifier and (not character in Chars.IDENTIFIER_CHARSET):
		text += character
		is_valid_identifier = false
		is_inline_text = true
		type = Tokens.INLINE_TEXT
	elif is_operator and (not character in Chars.OPERATOR_CHARS):
		text += character
		is_operator = false
		is_inline_text = true
		type = Tokens.INLINE_TEXT
	elif is_regular_integer and (not character in Chars.REGULAR_INTEGER_CHARSET):
		if character == Chars.DOT:
			text += character
			is_regular_integer = false
			is_regular_float = true
			type = Tokens.FLOAT
		elif text == "0" and character == "x":
			text += character
			is_regular_integer = false
			is_hex_integer = true
			assert(type == Tokens.INT)
		elif text == "0" and character == "b":
			text += character
			is_regular_integer = false
			is_binary_integer = true
			assert(type == Tokens.INT)
		else:
			is_regular_integer = false
			is_inline_text = true
			type = Tokens.INLINE_TEXT
	elif is_regular_float and (not character in Chars.DIGITS):
		if character == "e":
			text += character
			is_regular_float = false
			is_scientific_notation_float = true
			assert(type == Tokens.FLOAT)
	elif is_scientific_notation_float:
		if text.ends_with("e"):
			if not character in "+-" + Chars.DIGITS:
				is_scientific_notation_float = false
				is_inline_text = true
				type = Tokens.INLINE_TEXT
		else:
			if not character in Chars.DIGITS:
				is_scientific_notation_float = false
				is_inline_text = true
				type = Tokens.INLINE_TEXT
		text += character
	else:
		text += character
