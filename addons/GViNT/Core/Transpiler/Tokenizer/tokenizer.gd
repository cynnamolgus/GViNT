@tool
extends RefCounted
## GViNT tokenizer.
##
## Largely based on Godot's GDScript tokenizer: 
## https://github.com/godotengine/godot/blob/ee121ef80e36865ac9d5c55ab2ec419f48ef6954/modules/gdscript/gdscript_tokenizer.cpp


#region: character constants
const SPACE = " "
const TAB = "	"
const WHITESPACE = SPACE + TAB

const CARRIAGE_RETURN = "\r"
const LINEBREAK = "\n"
const BACKSLASH = "\\"

const COMMENT_MARK = "#"

const UNDERSCORE = "_"
const COLON = ":"
const DOT = "."
const COMMA = ","

const QUOTE = '"'
const SINGLE_QUOTE = "'"
const RAW_STRING_MARK = "r"
const U = "u"
const UPPERCASE_U = "U"
const ESCAPE_CHARACTERS = "abfnrtv'\"\\uU"

const OPEN_BRACE = "{"
const CLOSE_BRACE = "}"

const OPEN_BRACKET = "["
const CLOSE_BRACKET = "]"

const OPEN_PARENTHESIS = "("
const CLOSE_PARENTHESIS = ")"

const EQUALS = "="
const PLUS = "+"
const MINUS = "-"
const STAR = "*"
const SLASH = "/"
const PERCENT = "%"
const EXCLAMATION = "!"
const PIPE = "|"
const AMPERSAND = "&"
const CARET = "^"
const TILDE = "~"
const LESS = "<"
const GREATER = ">"

const ZERO = "0"
const DIGITS = "0123456789"
const HEXADECIMAL_DIGITS = "abcdefABCDEF" + DIGITS

const E = "e"
const UPPERCASE_E = "E"
const REGULAR_NUMBER_CHARSET = DIGITS + UNDERSCORE

const X = "x"
const UPPERCASE_X = "X"
const HEXADECIMAL_INTEGER_CHARSET = HEXADECIMAL_DIGITS + UNDERSCORE

const B = "b"
const UPPERCASE_B = "B"
const BINARY_INTEGER_CHARSET = "01" + UNDERSCORE

const ALWAYS_SINGLE_CHARACTER_TOKENS = (
	OPEN_BRACE + CLOSE_BRACE
	+ OPEN_BRACKET + CLOSE_BRACKET
	+ OPEN_PARENTHESIS + CLOSE_PARENTHESIS
	+ COMMA
	+ COLON
	+ TILDE
)
#endregion

#region: keywords
const KEYWORD_TRUE = "true"
const KEYWORD_FALSE = "false"
const KEYWORD_NULL = "null"

const KEYWORD_AWAIT = "await"
const KEYWORD_NOT = "not"
const KEYWORD_OR = "or"
const KEYWORD_AND = "and"
const KEYWORD_IN = "in"
const KEYWORD_IS = "is"
const KEYWORD_AS = "as"
const KEYWORD_IF = "if"
const KEYWORD_ELSE = "else"
const KEYWORD_ELIF = "elif"

const KEYWORD_LITERALS = [
	KEYWORD_TRUE,
	KEYWORD_FALSE,
	KEYWORD_NULL,
]

const KEYWORDS = [
	KEYWORD_AWAIT,
	KEYWORD_NOT,
	KEYWORD_OR,
	KEYWORD_AND,
	KEYWORD_IN,
	KEYWORD_IS,
	KEYWORD_AS,
	KEYWORD_IF,
	KEYWORD_ELSE,
	KEYWORD_ELIF,
]
#endregion

const Token = Gvint.Token
const GDScriptBuiltins = Gvint.GDScriptBuiltins

var _source_code: String
var _position: int
var _current_character: String
var _current_line
var _current_column
var _token_start_position: int
var _token_start_line: int
var _token_start_column: int

var _custom_types: Array = ProjectSettings.get_global_class_list().map(func(element): return element.class)

var result := Gvint.TokenizeResult.new()


func _init(source_code: String) -> void:
	if not source_code.ends_with(LINEBREAK):
		source_code += LINEBREAK
	
	_source_code = source_code
	_position = 0
	_current_column = 0
	_current_line = 0
	


static func tokenize_text(text: String) -> Gvint.TokenizeResult:
	var tokenizer := Gvint.Tokenizer.new(text)
	while not tokenizer.end_reached():
		tokenizer.scan_next_token()
	return tokenizer.result


func end_reached() -> bool:
	return _position >= _source_code.length()


func scan_next_token() -> void:
	if end_reached():
		return
	
	_skip_whitespace_and_linebreaks()
	
	if end_reached():
		return
	
	_token_start_position = _position
	_token_start_line = _current_line
	_token_start_column = _current_column
	_advance()
	assert(_current_character != "")
	
	if _current_character == BACKSLASH:
		if _peek() == CARRIAGE_RETURN:
			if _peek(1) != LINEBREAK:
				_add_error("Unexpected carriage return character.")
				return
			_advance()
		if _peek() != LINEBREAK:
			_add_error('Expected new line after "\\"')
			return
		_advance()
		return
	
	# raw strings
	if _current_character == "r" and (_peek() == QUOTE or _peek() == SINGLE_QUOTE):
		_add_string_literal()
		return
	
	if _current_character in ALWAYS_SINGLE_CHARACTER_TOKENS:
		_add_token(_current_character, _current_character)
		return
	
	if _current_character.is_valid_unicode_identifier():
		_add_valid_identifier()
		return
	
	if _current_character in DIGITS:
		_add_number()
		return
	
	match _current_character:
		COMMENT_MARK:
			_skip_to_next_line()
			scan_next_token()
		QUOTE, SINGLE_QUOTE:
			_add_string_literal()
		EXCLAMATION:
			if _peek() == EQUALS:
				_advance()
				_add_token(Token.EXCLAMATION_EQUALS, EXCLAMATION + EQUALS)
			else:
				_add_token(Token.EXCLAMATION, EXCLAMATION)
		DOT:
			if _peek() in DIGITS:
				_add_number()
			else:
				_add_token(Token.DOT, DOT)
		PLUS:
			if _peek() == EQUALS:
				_advance()
				_add_token(Token.PLUS_EQUALS, PLUS + EQUALS)
			elif _peek() in DIGITS and not _last_token_can_precede_arithmetic_operator():
				_add_number()
			else:
				_add_token(Token.PLUS, PLUS)
		MINUS:
			if _peek() == EQUALS:
				_advance()
				_add_token(Token.MINUS_EQUALS, MINUS + EQUALS)
			elif _peek() in DIGITS and not _last_token_can_precede_arithmetic_operator():
				_add_number()
			else:
				_add_token(Token.MINUS, MINUS)
		STAR:
			if _peek() == EQUALS:
				_advance()
				_add_token(Token.STAR_EQUALS, STAR + EQUALS)
			elif _peek() == STAR:
				if _peek(1) == EQUALS:
					_advance()
					_advance()
					_add_token(Token.STAR_STAR_EQUALS, STAR + STAR + EQUALS)
				else:
					_advance()
					_add_token(Token.STAR_STAR, STAR + STAR)
			else:
				_add_token(Token.STAR, STAR)
		SLASH:
			if _peek() == EQUALS:
				_advance()
				_add_token(Token.SLASH_EQUALS, SLASH + EQUALS)
			else:
				_add_token(Token.SLASH, SLASH)
		PERCENT:
			if _peek() == EQUALS:
				_advance()
				_add_token(Token.PERCENT_EQUALS, PERCENT + EQUALS)
			else:
				_add_token(Token.PERCENT, PERCENT)
		CARET:
			if _peek() == EQUALS:
				_advance()
				_add_token(Token.CARET_EQUALS, CARET + EQUALS)
			elif (_peek() == QUOTE) or (_peek() == SINGLE_QUOTE):
				# NodePath literal
				_add_string_literal()
			else:
				_add_token(Token.CARET, CARET)
		AMPERSAND:
			if _peek() == AMPERSAND:
				_advance()
				_add_token(Token.AMPERSAND_AMPERSAND, AMPERSAND + AMPERSAND)
			elif _peek() == EQUALS:
				_advance()
				_add_token(Token.AMPERSAND_EQUALS, AMPERSAND + EQUALS)
			elif (_peek() == QUOTE) or (_peek() == SINGLE_QUOTE):
				# StringName literal
				_add_string_literal()
			else:
				_add_token(Token.AMPERSAND, AMPERSAND)
		PIPE:
			if _peek() == PIPE:
				_advance()
				_add_token(Token.PIPE_PIPE, PIPE + PIPE)
			elif _peek() == EQUALS:
				_advance()
				_add_token(Token.PIPE_EQUALS, PIPE + EQUALS)
			else:
				_add_token(Token.PIPE, PIPE)
		EQUALS:
			if _peek() == EQUALS:
				_advance()
				_add_token(Token.EQUALS_EQUALS, EQUALS + EQUALS)
			else:
				_add_token(Token.EQUALS, EQUALS)
		LESS:
			if _peek() == EQUALS:
				_advance()
				_add_token(Token.LESS_EQUALS, LESS + EQUALS)
			elif _peek() == LESS:
				if _peek(1) == EQUALS:
					_advance()
					_advance()
					_add_token(Token.LESS_LESS_EQUALS, LESS + LESS + EQUALS)
				else:
					_advance()
					_add_token(Token.LESS_LESS, LESS + LESS)
			else:
				_add_token(Token.LESS, LESS)
		GREATER:
			if _peek() == EQUALS:
				_advance()
				_add_token(Token.GREATER_EQUALS, GREATER + EQUALS)
			elif _peek() == GREATER:
				if _peek(1) == EQUALS:
					_advance()
					_advance()
					_add_token(Token.GREATER_GREATER_EQUALS, GREATER + GREATER + EQUALS)
				else:
					_advance()
					_add_token(Token.GREATER_GREATER, GREATER + GREATER)
			else:
				_add_token(Token.GREATER, GREATER)
		_:
			_add_error('Invalid character "%s" (U+%04X)' \
					% [_current_character, _current_character.unicode_at(0)])


func _skip_whitespace_and_linebreaks() -> void:
	while _peek() in (WHITESPACE + CARRIAGE_RETURN + LINEBREAK):
		var is_crlf: bool = (_peek() == CARRIAGE_RETURN and _peek(1) == LINEBREAK)
		var is_linebreak: bool = (_peek() == LINEBREAK) or is_crlf
		if is_linebreak:
			_token_start_line = _current_line
			_token_start_column = _current_column
		_advance()
		if is_crlf:
			_advance()
		if is_linebreak:
			_add_token(Token.LINEBREAK, LINEBREAK)


func _skip_whitespace() -> void:
	while _peek() in WHITESPACE:
		_advance()


func _skip_linebreaks() -> void:
	var is_crlf: bool = (_peek() == CARRIAGE_RETURN and _peek(1) == LINEBREAK)
	while _peek() == LINEBREAK or is_crlf:
		_token_start_line = _current_line
		_token_start_column = _current_column
		if is_crlf:
			_advance()
			_advance()
		else:
			_advance()
		_add_token(Token.LINEBREAK, LINEBREAK)
		is_crlf = (_peek() == CARRIAGE_RETURN and _peek(1) == LINEBREAK)


func _skip_to_next_line() -> void:
	_position = _source_code.find(LINEBREAK, _position)
	_skip_linebreaks()


func _add_token(type: String, text_content: String = "") -> void:
	var token := Token.new()
	token.type = type
	token.text_content = text_content
	token.start_line = _token_start_line
	token.start_column = _token_start_column
	if type == Token.LINEBREAK:
		token.end_line = _current_line - 1
		token.end_column = _token_start_column + 1
	else:
		token.end_line = _current_line
		token.end_column = _current_column
	result.tokens.append(token)


func _add_valid_identifier() -> void:
	_advance()
	while _peek().is_valid_unicode_identifier() or _peek() in DIGITS:
		_advance()
	var token_length: int = _position - _token_start_position
	if token_length == 1 and _current_character == UNDERSCORE:
		_add_token(Token.UNDERSCORE, UNDERSCORE)
		return
	var token_text: String = _source_code.substr(_token_start_position, token_length)
	
	if token_text in KEYWORD_LITERALS:
		_add_token(Token.LITERAL, token_text)
	elif token_text in KEYWORDS:
		_add_token(token_text, token_text)
	elif token_text in GDScriptBuiltins.RESERVED_KEYWORDS:
		_add_error('Used GDScript reserved keyword "%s"' % token_text, _current_line, _token_start_column)
	elif token_text in GDScriptBuiltins.BUILTIN_FUNCTIONS:
		_add_token(Token.BUILTIN_FUNC, token_text)
	elif token_text in GDScriptBuiltins.BUILTIN_CONSTANTS:
		_add_token(Token.BUILTIN_CONST, token_text)
	elif Engine.has_singleton(token_text):
		_add_token(Token.ENGINE_SINGLETON, token_text)
	elif token_text in GDScriptBuiltins.BUILTIN_TYPES:
		_add_token(Token.BUILTIN_TYPE, token_text)
	elif type_exists(token_text) or token_text in _custom_types:
		_add_token(Token.TYPE, token_text)
	else:
		_add_token(Token.IDENTIFIER, token_text)


func _add_number() -> void:
	var base: int = 10
	var has_decimal: bool = false
	var has_error: bool = false
	var need_digits: bool = false
	
	var number_charset: String = REGULAR_NUMBER_CHARSET
	
	# skip sign before hexadecimal or binary
	if (_current_character == PLUS or _current_character == MINUS) and _peek() == ZERO:
		_advance()
	
	if _current_character == DOT:
		has_decimal = true
	elif _current_character == ZERO:
		if _peek() == X or _peek() == UPPERCASE_X:
			base = 16
			number_charset = HEXADECIMAL_INTEGER_CHARSET
			need_digits = true
			_advance()
		elif _peek() == B or _peek() == UPPERCASE_B:
			base = 2
			number_charset = BINARY_INTEGER_CHARSET
			need_digits = true
			_advance()
	
	# disallow "0x_" and "0b_"
	if base != 10 and _peek() == UNDERSCORE:
		_add_error('Unexpected underscore after "0%s"' % _current_character)
		has_error = true
	
	# consume digits before potential decimal point, 
	# or after the decimal point if there were no leading digits (eg ".1")
	var previous_char_was_underscore: bool = false
	while _peek() in number_charset:
		if _peek() == UNDERSCORE:
			if previous_char_was_underscore:
				_add_error('Multiple underscores cannot be adjacent in a numeric literal.')
			previous_char_was_underscore = true
		else:
			need_digits = false
			previous_char_was_underscore = false
		_advance()
	
	# check for decimal point
	if _peek() == DOT:
		if base == 10 and not has_decimal:
			has_decimal = true
		elif base == 10:
			_add_error("Cannot use a decimal point twice in a number.", _current_line, _current_column)
			has_error = true
		elif base == 16:
			_add_error("Cannot use a decimal point in a hexadecimal number.", _current_line, _current_column)
			has_error = true
		elif base == 2:
			_add_error("Cannot use a decimal point in a binary number.", _current_line, _current_column)
			has_error = true
		
		if not has_error:
			_advance()
			
			# consume digits after decimal point
			if _peek() == UNDERSCORE:
				_add_error("Unexpected underscore after a decimal point.", _current_line, _current_column)
				has_error = true
			previous_char_was_underscore = false
			while _peek() in number_charset:
				if _peek() == UNDERSCORE:
					if previous_char_was_underscore:
						_add_error('Multiple underscores cannot be adjacent in a numeric literal.')
					previous_char_was_underscore = true
				else:
					previous_char_was_underscore = false
				_advance()
	
	# check for and process exponent
	if base == 10:
		if _peek() == E or _peek() == UPPERCASE_E:
			_advance()
			if _peek() == PLUS or _peek() == MINUS:
				_advance()
			if not _peek() in number_charset:
				_add_error('Expected exponent value after "e".')
			
			# consume exponent digits
			previous_char_was_underscore = false
			while _peek() in number_charset:
				if _peek() == UNDERSCORE:
					if previous_char_was_underscore:
						_add_error('Multiple underscores cannot be adjacent in a numeric literal.')
					previous_char_was_underscore = true
				else:
					previous_char_was_underscore = false
				_advance()
	
	if need_digits:
		if base == 16:
			_add_error('Expected hexadecimal digit after "0x".')
		elif base == 2:
			_add_error('Expected binary digit after "0b".')
		return
	
	# detect extra decimal point
	if not has_error and has_decimal and _peek() == DOT:
		_add_error("Cannot use a decimal point twice in a number.", _current_line, _current_column)
		has_error = true
	
	var token_length: int = _position - _token_start_position
	var token_text: String = _source_code.substr(_token_start_position, token_length)
	_add_token(Token.LITERAL, token_text)


func _add_string_literal() -> void:
	var is_multiline: bool = false
	var is_raw: bool = false
	var token_text: String = ""
	
	# consume raw string prefix
	if _current_character == RAW_STRING_MARK:
		is_raw = true
		token_text += _current_character
		_advance()
	# consume StringName or NodePath prefix
	elif _current_character in AMPERSAND + CARET:
		token_text += _current_character
		_advance()
	
	var quote_char: String = _current_character
	token_text += quote_char
	if _peek() == quote_char and _peek(1) == quote_char:
		is_multiline = true
		token_text += quote_char + quote_char
		_advance()
		_advance()
	
	var next_char: String
	var previous_unicode_surrogate: int
	# process the string
	while true:
		if end_reached():
			_add_error("Unterminated string.", _token_start_line, _token_start_column)
			return
		
		next_char = _peek()
		var unicode = next_char.unicode_at(0)
		var next_char_is_text_direction_control: bool = (
				unicode == 0x200E 
				or unicode == 0x200F 
				or (unicode >= 0x202A and unicode <= 0x202E)
				or (unicode >= 0x2066 and unicode <= 0x2069)
		)
		if next_char_is_text_direction_control:
			if is_raw:
				_add_error(
						"Invisible text direction control character present in the string, use regular string literal instead of r-string.",
						_current_line,
						_current_column
				)
			else:
				_add_error(
						'Invisible text direction control character present in the string, escape it ("\\u%x") to avoid confusion' % unicode,
						_current_line,
						_current_column
				)
		
		# escape pattern
		if next_char == BACKSLASH:
			token_text += _advance()
			if is_raw:
				if _peek() == quote_char or _peek() == BACKSLASH:
					token_text += _advance()
					if end_reached():
						_add_error("Unterminated string.", _token_start_line, _token_start_column)
						return
			else:
				var escape_code := _peek()
				var escaped_unicode_value: int = 0
				token_text += _advance()
				if end_reached():
					_add_error("Unterminated string.", _token_start_line, _token_start_column)
					return
				var valid_escape: bool = true
				# process hexadecimal unicode sequence
				if escape_code == U or escape_code == UPPERCASE_U:
					var hex_len: int = 6 if escape_code == UPPERCASE_U else 4
					var digit: String
					var escape_hex_string: String = ""
					for i in range(hex_len):
						digit = _peek()
						if digit in HEXADECIMAL_DIGITS:
							escape_hex_string += digit
						else:
							_add_error("Invalid hexadecimal digit in unicode escape sequence.", _current_line, _current_column)
							valid_escape = false
							break
						token_text += _advance()
					if valid_escape:
						escaped_unicode_value = escape_hex_string.hex_to_int()
				elif escape_code == CARRIAGE_RETURN:
					if _peek() == LINEBREAK:
						token_text = token_text.trim_suffix(BACKSLASH + CARRIAGE_RETURN)
						_advance()
				elif escape_code == LINEBREAK:
					token_text = token_text.trim_suffix(BACKSLASH + LINEBREAK)
				elif not escape_code in ESCAPE_CHARACTERS:
					_add_error("Invalid escape in string.", _current_line, _current_column - 2)
				
				if valid_escape:
					if (escaped_unicode_value & 0xfffffc00) == 0xd800:
						if previous_unicode_surrogate == 0:
							previous_unicode_surrogate = escaped_unicode_value
							continue
						else:
							_add_error(
									"Invalid UTF-16 sequence in string, unpaired lead surrogate.",
									_token_start_line,
									_token_start_column
							)
							valid_escape = false
							previous_unicode_surrogate = 0
					elif (escaped_unicode_value & 0xfffffc00) == 0xdc00:
						if previous_unicode_surrogate == 0:
							_add_error(
									"Invalid UTF-16 sequence in string, unpaired trail surrogate.",
									_token_start_line,
									_token_start_column
							)
							valid_escape = false
						else:
							escaped_unicode_value = (
									(previous_unicode_surrogate << 10)
									+ escaped_unicode_value
									- ((0xd800 << 10) + 0xdc00 - 0x10000)
							)
							previous_unicode_surrogate = 0
					if previous_unicode_surrogate != 0:
						_add_error(
								"Invalid UTF-16 sequence in string, unpaired lead surrogate.",
								_token_start_line,
								_token_start_column
						)
		elif next_char == quote_char:
			if previous_unicode_surrogate != 0:
				_add_error(
						"Invalid UTF-16 sequence in string, unpaired lead surrogate.",
						_token_start_line,
						_token_start_column
				)
			token_text += _advance()
			if is_multiline:
				if _peek() == quote_char and _peek(1) == quote_char:
					token_text += _advance() + _advance()
					break
			else:
				break
		else:
			if previous_unicode_surrogate != 0:
				_add_error(
						"Invalid UTF-16 sequence in string, unpaired lead surrogate.",
						_token_start_line,
						_token_start_column
				)
				previous_unicode_surrogate = 0
			token_text += _advance()
	
	_add_token(Token.LITERAL, token_text)


func _add_error(error_text: String, line: int = -1, column: int = -1) -> void:
	if line == -1:
		line = _current_line
	if column == -1:
		column = _current_column - 1
	var error := Gvint.TokenizeError.new()
	error.text = error_text
	error.line = line
	error.column = column
	result.errors.append(error)


func _last_token_can_precede_arithmetic_operator() -> bool:
	if result.tokens.is_empty():
		return false
	var last_token: Token = result.tokens.back()
	match last_token.type:
		Token.IDENTIFIER,\
		Token.LITERAL,\
		Token.BRACKET_CLOSE,\
		Token.BRACE_CLOSE,\
		Token.PARENTHESIS_CLOSE,\
		Token.BUILTIN_CONST:
			return true
		_:
			return false


func _advance() -> String:
	_position += 1
	_current_column += 1
	_current_character = _peek(-1)
	if _current_character == LINEBREAK:
		_current_line += 1
		_current_column = 0
	return _current_character


func _peek(offset: int = 0) -> String:
	if (_position + offset) < 0:
		return ""
	if (_position + offset) >= _source_code.length():
		return ""
	return _source_code[_position + offset]
