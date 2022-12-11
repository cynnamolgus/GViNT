extends Reference



const Tokenizer = preload("res://GViNT/Translator/Tokenizer/Tokenizer.gd")
const TokenizeResult = preload("res://GViNT/Translator/Tokenizer/TokenizeResult.gd")
const Token = preload("res://GViNT/Translator/Tokenizer/Token.gd")

const Tokens = preload("res://GViNT/Translator/Tokenizer/Tokens.gd")
const Chars = preload("res://GViNT/Translator/Characters.gd")

const SetVariable = preload("res://GViNT/Translator/Instructions/SetVariable.gd")
const CallFunction = preload("res://GViNT/Translator/Instructions/CallFunction.gd")
const DisplayText = preload("res://GViNT/Translator/Instructions/DisplayText.gd")



var tokenizer := Tokenizer.new()

var unpaired_tokens := []

var current_instruction

var instruction_buffer := []
var identifier_buffer := []

var identifier_is_settable := false
var identifier_buffer_open := true



func read_file(file: String) -> String:
	var content: String
	var f := File.new()
	f.open(file, File.READ)
	content = f.get_as_text()
	f.close()
	return content


func translate_file(file: String):
	var source_code := read_file(file)
	tokenizer.clear()
	var tokenize_result := tokenizer.tokenize_text(source_code)
	var gdscript_sources := translate_tokens(tokenize_result.tokens)
	return gdscript_sources


func translate_tokens(tokens) -> Array:
	var gdscript_sources := []
	
	for t in tokens:
		update_paired_tokens(t)
		update_identifier_buffer(t)
		if token_ends_instruction(t) and instruction_buffer:
			var gdscript_instruction = end_instruction()
			gdscript_sources.append(gdscript_instruction)
		elif t.type != Tokens.LINEBREAK:
			instruction_buffer.append(t)
	
	return gdscript_sources


func token_ends_instruction(token: Token) -> bool:
	return (
		token.type == Tokens.LINEBREAK 
		and unpaired_tokens.empty()
	) or token.type == Tokens.END_OF_FILE


func update_identifier_buffer(token: Token):
	identifier_is_settable = (
		token.type == Tokens.IDENTIFIER
		or token.type == Tokens.CLOSE_BRACKET
	)
	
	var token_opens_buffer = (
		token.type == Tokens.OPERATOR
		or token.type == Tokens.ASSIGN
		or token.type == Tokens.LINEBREAK
		or token.type == Tokens.COMMA
		or token.type == Tokens.COLON
		or token.type in Tokens.OPENING_TOKENS
	)
	
	if identifier_buffer_open:
		if (token.type == Tokens.IDENTIFIER
		  or token.type == Tokens.DOT):
			identifier_buffer.append(token)
		elif token_opens_buffer:
			flush_identifier_buffer()
		else:
			flush_identifier_buffer()
			identifier_buffer_open = false
	elif token_opens_buffer:
		identifier_buffer_open = true


func update_paired_tokens(token: Token):
	if token.type in Tokens.OPENING_TOKENS:
		unpaired_tokens.append(token.type)
	elif unpaired_tokens:
		if token.type == Tokens.CLOSING_TOKENS[unpaired_tokens.back()]:
			unpaired_tokens.pop_back()


func flush_identifier_buffer():
	if identifier_buffer.empty():
		return
	
	#todo: proper identifier expansion. placeholder for testing.
	var first_identifier: Token = identifier_buffer[0]
	var is_builtin_or_global = first_identifier.text[0] in Chars.UPPERCASE
	if not is_builtin_or_global:
		identifier_buffer[0].text = "runtime." + identifier_buffer[0].text
	identifier_buffer.clear()


func end_instruction():
	var InstructionType = check_buffered_instruction_type()
	current_instruction = InstructionType.new()
	current_instruction.construct_from_tokens(instruction_buffer)
	instruction_buffer.clear()
	
	# todo: generalize script translation config
	if current_instruction is DisplayText:
		current_instruction.target = "runtime"
		current_instruction.method = "display_text"
		current_instruction.undo_method = "undo_display_text"
	elif current_instruction is CallFunction:
		current_instruction.undo_method = "undo_" + current_instruction.method
	
	return current_instruction.to_gdscript()


func check_buffered_instruction_type():
	assert(instruction_buffer)
	if instruction_buffer[0].type == Tokens.STRING:
		return DisplayText
	
	var colons := 0
	var assignments := 0
	var dict_level := 0
	for t in instruction_buffer:
		match t.type:
			Tokens.OPEN_BRACE:
				dict_level += 1
			Tokens.CLOSE_BRACE:
				dict_level -= 1
			Tokens.COLON:
				if dict_level == 0:
					colons += 1
			Tokens.ASSIGN:
				assignments += 1
	
	if colons:
		assert(colons == 1)
		return DisplayText
	if assignments:
		assert(assignments == 1)
		return SetVariable
	return CallFunction

