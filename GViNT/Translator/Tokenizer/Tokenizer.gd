extends Node

const TokenizeResult = preload("res://GViNT/Translator/Tokenizer/TokenizeResult.gd")
const Token = preload("res://GViNT/Translator/Tokenizer/Token.gd")

const Chars = preload("res://GViNT/Translator/Characters.gd")
const Tokens = preload("res://GViNT/Translator/Tokenizer/Tokens.gd")
const Gdscript = preload("res://GViNT/Translator/GDScriptBuiltins.gd")

var current_line: int
var tokenized_lines := []

var source_code: String
var source_filename: String
var current_character: int
var current_token: Token

var used_blocked_keywords := []
var used_blocked_functions := []
var used_builtin_functions := []
var used_builtin_constants := []

var tokenize_result: TokenizeResult



func clear():
	current_line = -1
	tokenized_lines = []
	source_code = ""
	source_filename = ""
	current_character = -1
	current_token = null
	tokenize_result = null


func update_line(tokenize_result, line_index, script):
	#TODO - implement re-tokenizing of selected lines
	#will function as an optimization for script editor
	#(avoids re-processing full file from scratch every time the text is updated)
	pass


func tokenize_text(text: String):
	tokenized_lines = [[]]
	update_builtin_check_cache(text)
	
	current_line = 0
	current_character = 0
	source_code = text
	
	current_token = Token.new()
	current_token.source_filename = source_filename
	current_token.source_line = current_line
	
	if not source_code.ends_with(Chars.LINEBREAK):
		source_code += Chars.LINEBREAK
	
	var source_length := len(text)
	while current_character < source_length:
		process_source()
	
	mark_token_types(tokenized_lines)
	tokenize_result = TokenizeResult.new()
	store_result_data(tokenize_result)


func update_builtin_check_cache(text: String):
	for function in Gdscript.BLOCKED_FUNCTIONS:
		if function in text:
			used_blocked_functions.append(function)
	for keyword in Gdscript.RESERVED_KEYWORDS:
		if keyword in text:
			used_blocked_keywords.append(keyword)
	for function in Gdscript.BUILTIN_FUNCTIONS:
		if function in text:
			used_builtin_functions.append(function)
	for constant in Gdscript.BUILTIN_CONSTANTS:
		if constant in text:
			used_builtin_constants.append(constant)


func start_tokenize_result(source_code: String, source_filename: String):
	tokenize_result = TokenizeResult.new()
	tokenize_result.source_code = source_code
	tokenize_result.source_filename = source_filename
	tokenized_lines = [[]]
	used_blocked_keywords = []
	used_blocked_functions = []
	used_builtin_functions = []
	used_builtin_constants = []


func store_result_data(tokenize_result: TokenizeResult):
	tokenize_result.source_code = source_code
	tokenize_result.source_filename = source_filename
	tokenize_result.used_blocked_keywords = used_blocked_keywords
	tokenize_result.used_blocked_functions = used_blocked_functions
	tokenize_result.used_builtin_functions = used_builtin_functions
	tokenize_result.used_builtin_constants = used_builtin_constants
	tokenize_result.tokenized_lines = tokenized_lines


func start_new_token():
	assert(current_token.type or current_token.text)
	tokenized_lines.back().append(current_token)
	current_token = Token.new()
	current_token.source_filename = source_filename
	current_token.source_line = current_line


func process_source():
	if current_token.is_inline_text:
		tokenize_inline_text()
	
	var character: String = source_code[current_character]
	
	if character == Chars.SPACE:
		skip_consecutive_spaces()
	elif character == Chars.COMMENT_MARK:
		current_character = source_code.find(Chars.LINEBREAK, current_character)
		character = source_code[current_character]
	
	if current_token.text.empty():
		if character in Token.ALWAYS_SINGLE_CHARACTER_TOKENS:
			tokenize_single_character(character)
		elif character == Chars.QUOTE:
			tokenize_string_literal()
		elif character == Chars.SPACE:
			current_character += 1
		else:
			current_token.start(character)
			current_character += 1
	else:
		if check_end_of_token(character):
			start_new_token()
		else:
			current_token.add_character(character)
			current_character += 1


func tokenize_inline_text():
	var next_linebreak_index = source_code.find(Chars.LINEBREAK, current_character) - 1
	current_token.type = Tokens.INLINE_TEXT
	current_token.text += source_code.substr(current_character, next_linebreak_index - 1)
	current_character += (next_linebreak_index - current_character) + 1
	start_new_token()


func skip_consecutive_spaces():
	while source_code[current_character + 1] == Chars.SPACE:
		current_character += 1


#todo - multiline comments. too tired to implement this right now
#func skip_comments():
#	var consecutive_comment_marks: int = 1
#	while consecutive_comment_marks < 3:
#		if source_code[current_character + 1] == Chars.COMMENT_MARK:
#			consecutive_comment_marks += 1
#			current_character += 1
#		else:
#			break
#	if consecutive_comment_marks == 3:
#		var multiline_comment_end = source_code.find(Chars.MULTILINE_COMMENT_MARK, current_character)
#		if multiline_comment_end != -1:
#			current_character = multiline_comment_end + 3
#	else:
#		current_character = source_code.find(Chars.LINEBREAK, current_character)


func tokenize_single_character(character: String):
	current_token.text = character
	start_new_token()
	if character == Chars.LINEBREAK:
		tokenized_lines.append([])
		current_line += 1
	current_character += 1


func tokenize_string_literal():
	var end_index = get_next_nonescaped_quote_index(source_code, current_character)
	if end_index == -1:
		current_token.is_inline_text = true
		return
	
	var string_literal = source_code.substr(current_character, end_index - current_character + 1)
	assert(len(string_literal) >= 2)
	current_character += len(string_literal)
	
	var split_by_lines = string_literal.split(Chars.LINEBREAK)
	
	current_token.type = Tokens.STRING
	current_token.text = split_by_lines[0]
	split_by_lines.remove(0)
	
	if split_by_lines:
		current_token.text += Chars.LINEBREAK
		for multiline_part in split_by_lines:
			current_line += 1
			start_new_token()
			tokenized_lines.append([])
			current_token.text = multiline_part
			current_token.type = Tokens.STRING_MULTILINE_CONT
			if not multiline_part.ends_with(Chars.QUOTE):
				current_token.text += Chars.LINEBREAK
	start_new_token()


func get_next_nonescaped_quote_index(text: String, after: int):
	assert(not text.empty())
	assert(after >= 1)
	var next_quote_index = text.find(Chars.QUOTE, after + 1)
	var is_escaped = text[next_quote_index - 1] == Chars.BACKSLASH
	while is_escaped and next_quote_index != -1:
		after = next_quote_index
		next_quote_index = text.find(Chars.QUOTE, after + 1)
		is_escaped = text[next_quote_index - 1] == Chars.BACKSLASH
	if next_quote_index == -1:
		assert(false, "string literal missing closing quote mark") #todo - proper error handling
	return next_quote_index


func check_end_of_token(character: String):
	assert(len(character) == 1)
	assert(current_token)
	assert(len(current_token.text) >= 1)
	
	var end_of_token := false
	
	if character == Chars.SPACE:
		current_character += 1
	
	if current_token.is_operator:
		end_of_token = (character in (Chars.TERMINATING_CHARS + Chars.IDENTIFIER_CHARSET))
	elif current_token.is_scientific_notation_float:
		end_of_token = (character in (Chars.TERMINATING_CHARS))
		if current_token.text[len(current_token.text) - 1] in Chars.DIGITS:
			end_of_token = end_of_token or (character in Chars.OPERATOR_CHARS)
	else:
		end_of_token = (character in (Chars.TERMINATING_CHARS + Chars.OPERATOR_CHARS))
		if not end_of_token:
			if current_token.is_valid_identifier:
				end_of_token = end_of_token or (character == Chars.DOT)
			elif current_token.is_regular_float:
				if character == Chars.DOT and (Chars.DOT in current_token.text):
					current_token.is_regular_float = false
					end_of_token = true
	return end_of_token


func add_eof_token():
	start_new_token()
	current_token.type = Tokens.END_OF_FILE
	pass


func mark_token_types(lines):
	for line in lines:
		for token in line:
			if not token.type:
				if token.is_valid_identifier:
					mark_token_identifier_type(token)
				elif token.is_operator:
					mark_token_operator_type(token)
				elif len(token.text) == 1:
					mark_single_character_token(token)


func mark_single_character_token(token: Token):
	match token.text:
		Chars.LINEBREAK: token.type = Tokens.LINEBREAK
		Chars.DOT: token.type = Tokens.DOT
		Chars.COMMA: token.type = Tokens.COMMA
		Chars.COLON: token.type = Tokens.COLON
		Chars.OPEN_BRACE: token.type = Tokens.OPEN_BRACE
		Chars.CLOSE_BRACE: token.type = Tokens.CLOSE_BRACE
		Chars.OPEN_BRACKET: token.type = Tokens.OPEN_BRACKET
		Chars.CLOSE_BRACKET: token.type = Tokens.CLOSE_BRACKET
		Chars.OPEN_PARENTHESIS: token.type = Tokens.OPEN_PARENTHESIS
		Chars.CLOSE_PARENTHESIS: token.type = Tokens.CLOSE_PARENTHESIS


func mark_token_identifier_type(token: Token):
	if token.text in used_blocked_keywords:
		token.type = Tokens.BLOCKED_KEYWORD
	elif token.text in used_builtin_constants:
		token.type = Tokens.GDSCRIPT_CONST
	elif token.text in used_builtin_functions:
		token.type = Tokens.GDSCRIPT_FUNC
	elif token.text in used_blocked_functions:
		token.type = Tokens.BLOCKED_FUNC
	else:
		match token.text:
			"true": token.type = Tokens.KEYWORD_TRUE
			"false": token.type = Tokens.KEYWORD_FALSE
			"if": token.type = Tokens.KEYWORD_IF
			"else": token.type = Tokens.KEYWORD_ELSE
			"elif": token.type = Tokens.KEYWORD_ELIF
			"not": token.type = Tokens.KEYWORD_NOT
			"or": token.type = Tokens.KEYWORD_OR
			"and": token.type = Tokens.KEYWORD_AND
			"in": token.type = Tokens.KEYWORD_IN
			"return": token.type = Tokens.KEYWORD_RETURN
			"as": token.type = Tokens.KEYWORD_AS
			_: token.type = Tokens.IDENTIFIER


func mark_token_operator_type(token: Token):
	match token.text:
		#arithmetic operators
		"+": token.type = Tokens.OP_ADD
		"-": token.type = Tokens.OP_SUBTRACT
		"*": token.type = Tokens.OP_MULTIPLY
		"/": token.type = Tokens.OP_DIVIDE
		"%": token.type = Tokens.OP_MODULO
		
		#assigmnent
		"=": token.type = Tokens.ASSIGN
		"+=": token.type = Tokens.ASSIGN_ADD
		"-=": token.type = Tokens.ASSIGN_SUBTRACT
		"*=": token.type = Tokens.ASSIGN_MULTIPLY
		"/=": token.type = Tokens.ASSIGN_DIVIDE
		"%=": token.type = Tokens.ASSIGN_MODULO
		"&=": token.type = Tokens.ASSIGN_AND
		"|=": token.type = Tokens.ASSIGN_OR
		">>=": token.type = Tokens.ASSIGN_SHIFT_RIGHT
		"<<=": token.type = Tokens.ASSIGN_SHIFT_LEFT
		
		#logical operators
		"==": token.type = Tokens.OP_EQUAL
		">=": token.type = Tokens.OP_GREATER_OR_EQUAL
		"<=": token.type = Tokens.OP_LESS_OR_EQUAL
		"!=": token.type = Tokens.OP_NOT_EQUAL
		"!": token.type = Tokens.OP_NEGATE
		"&&": token.type = Tokens.OP_AND
		"||": token.type = Tokens.OP_OR
		
		#bitwise operators
		">>": token.type = Tokens.OP_SHIFT_RIGHT
		"<<": token.type = Tokens.OP_SHIFT_LEFT
		"|": token.type = Tokens.OP_BITWISE_OR
		"&": token.type = Tokens.OP_BITWISE_AND
		"^": token.type = Tokens.OP_BITWISE_XOR
		"~": token.type = Tokens.OP_BITWISE_NOT
		
		_: token.type = Tokens.INLINE_TEXT

