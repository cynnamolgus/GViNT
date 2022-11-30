extends Node

const Token = preload("res://GViNT/Translator/Tokenizer/Token.gd")

const Chars = preload("res://GViNT/Translator/Characters.gd")
const Tokens = preload("res://GViNT/Translator/Tokenizer/Tokens.gd")


var current_line: int
var tokenized_lines := []

var source_code: String
var source_filename: String
var current_character: int
var current_token: Token


func tokenize_text(text: String):
	tokenized_lines = [[]]
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
	pass


func start_new_token():
	tokenized_lines.back().append(current_token)
	current_token = Token.new()
	current_token.source_filename = source_filename
	current_token.source_line = current_line
	pass


func process_source():
	if current_token.is_raw_text:
		var next_linebreak_index = source_code.find(Chars.LINEBREAK, current_character) - 1
		current_token.text += source_code.substr(current_character, next_linebreak_index - 1)
		current_character += (next_linebreak_index - current_character) + 1
		start_new_token()
	
	var character: String = source_code[current_character]
	
	if character == Chars.SPACE:
		while source_code[current_character + 1] == Chars.SPACE:
			current_character += 1
		character = source_code[current_character]
	
	if current_token.text.empty():
		if character in Token.ALWAYS_SINGLE_CHARACTER_TOKENS:
			current_token.text = character
			start_new_token()
			if character == Chars.LINEBREAK:
				tokenized_lines.append([])
				current_line += 1
			current_character += 1
		elif character == Chars.QUOTE:
			current_token.text = get_string_literal(source_code, current_character)
			assert(len(current_token.text) >= 2)
			current_character += len(current_token.text)
			var new_lines = current_token.text.count(Chars.LINEBREAK)
			start_new_token()
			for i in new_lines:
				tokenized_lines.append([])
			current_line += new_lines
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
		end_of_token = (character in (Chars.TERMINATING_CHARS)) #todo check for operators after scientific notation floats
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


func get_string_literal(text: String, start_index: int):
	assert(text[start_index] == Chars.QUOTE)
	var end_index = get_next_nonescaped_quote_index(text, start_index)
	return text.substr(start_index, end_index - start_index + 1)


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


func update_line(tokenize_result, line_index, script):
	#TODO - implement re-tokenizing of selected lines
	#will function as an optimization for script editor
	#(avoids re-processing full file from scratch every time the text is updated)
	pass




