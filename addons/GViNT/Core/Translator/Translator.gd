extends Reference



const Tokenizer = preload("res://addons/GViNT/Core/Translator/Tokenizer/Tokenizer.gd")
const TokenizeResult = preload("res://addons/GViNT/Core/Translator/Tokenizer/TokenizeResult.gd")
const Token = preload("res://addons/GViNT/Core/Translator/Tokenizer/Token.gd")

const Tokens = preload("res://addons/GViNT/Core/Translator/Tokenizer/Tokens.gd")
const Chars = preload("res://addons/GViNT/Core/Translator/Characters.gd")

const SetVariable = preload("res://addons/GViNT/Core/Translator/Instructions/SetVariable.gd")
const CallFunction = preload("res://addons/GViNT/Core/Translator/Instructions/CallFunction.gd")
const DisplayText = preload("res://addons/GViNT/Core/Translator/Instructions/DisplayText.gd")



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


func clear():
	tokenizer.clear()
	current_instruction = null
	instruction_buffer.clear()
	identifier_buffer.clear()
	identifier_is_settable = false
	identifier_buffer_open = true


func translate_file(file: String, config: Dictionary) -> Array:
	var source_code := read_file(file)
	var gdscript_sources := translate_source_code(source_code, config)
	return gdscript_sources


func translate_source_code(source_code: String, config: Dictionary) -> Array:
	clear()
	var tokenize_result := tokenizer.tokenize_text(source_code)
	var gdscript_sources := translate_tokens(tokenize_result.tokens, config)
	assert(instruction_buffer.empty())
	assert(identifier_buffer.empty())
	return gdscript_sources


func translate_tokens(tokens: Array, config: Dictionary) -> Array:
	var gdscript_sources := []
	
	for t in tokens:
		update_paired_tokens(t)
		update_identifier_buffer(t, config)
		if token_ends_instruction(t) and instruction_buffer:
			var gdscript_instruction = end_instruction(config)
			gdscript_sources.append(gdscript_instruction)
		elif (t.type != Tokens.LINEBREAK
		  and t.type != Tokens.END_OF_FILE):
			instruction_buffer.append(t)
	
	return gdscript_sources


func token_ends_instruction(token: Token) -> bool:
	return (
		token.type == Tokens.LINEBREAK 
		and unpaired_tokens.empty()
	) or token.type == Tokens.END_OF_FILE


func update_identifier_buffer(token: Token, config: Dictionary):
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
			flush_identifier_buffer(config)
		else:
			flush_identifier_buffer(config)
			identifier_buffer_open = false
	elif token_opens_buffer:
		identifier_buffer_open = true


func update_paired_tokens(token: Token):
	if token.type in Tokens.OPENING_TOKENS:
		unpaired_tokens.append(token.type)
	elif unpaired_tokens:
		if token.type == Tokens.CLOSING_TOKENS[unpaired_tokens.back()]:
			unpaired_tokens.pop_back()


func flush_identifier_buffer(config: Dictionary):
	if identifier_buffer.empty():
		return
	
	#todo: proper identifier expansion. placeholder for testing.
	var first_identifier: Token = identifier_buffer[0]
	var is_builtin_or_global = first_identifier.text[0] in Chars.UPPERCASE
	if not is_builtin_or_global:
		var identifier: String = identifier_buffer[0].text
		if identifier in config.shorthands:
			identifier = config.shorthands[identifier]
		identifier_buffer[0].text = "runtime." + identifier
	identifier_buffer.clear()


func end_instruction(config: Dictionary):
	current_instruction = instantiate_instruction_from_buffer()
	current_instruction.construct_from_tokens(instruction_buffer)
	instruction_buffer.clear()
	
	# todo: generalize script translation config
	if current_instruction is DisplayText:
		current_instruction.target = config.display_text_target
		current_instruction.method = config.display_text_method
		current_instruction.undo_method = config.display_text_undo
	elif current_instruction is CallFunction:
		current_instruction.undo_method = (
			config.default_undo_prefix
			+ current_instruction.method 
			+ config.default_undo_suffix 
		)
	
	return current_instruction.to_gdscript()


func instantiate_instruction_from_buffer():
	assert(instruction_buffer)
	
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
	
	var instance
	if colons:
		assert(colons == 1)
		instance = DisplayText.new()
		instance.has_params = true
		return instance
	elif instruction_buffer[0].type == Tokens.STRING:
		return DisplayText.new()
	if assignments:
		assert(assignments == 1)
		return SetVariable.new()
	return CallFunction.new()

