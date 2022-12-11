extends Reference



const Tokenizer = preload("res://GViNT/Translator/Tokenizer/Tokenizer.gd")
const TokenizeResult = preload("res://GViNT/Translator/Tokenizer/TokenizeResult.gd")
const Tokens = preload("res://GViNT/Translator/Tokenizer/Tokens.gd")
const Token = preload("res://GViNT/Translator/Tokenizer/Token.gd")

const SetVariable = preload("res://GViNT/Translator/Instructions/SetVariable.gd")
const CallFunction = preload("res://GViNT/Translator/Instructions/CallFunction.gd")
const DisplayText = preload("res://GViNT/Translator/Instructions/DisplayText.gd")

const TEMPLATE_FUNC = "res://GViNT/Translator/Templates/CallFunction.tres"
const TEMPLATE_SET = "res://GViNT/Translator/Templates/SetVariable.tres"


#parse/translate states
const UNKNOWN_INSTRUCTION = "UNKNOWN"
const CALL_FUNCTION = "CALL_FUNCTION"
const SET_VARIABLE = "SET_VARIABLE"
const DISPLAY_TEXT = "DISPLAY_TEXT"
const DISPLAY_TEXT_WITH_PARAMS = "DISPLAY_TEXT_PARAMS"

var template_function_call := ""
var template_set_variable := ""

var tokenizer := Tokenizer.new()

var state := ""
var opened_tokens := []

var current_instruction

var instruction_buffer := []
var identifier_buffer := []

var identifier_is_settable := false
var identifier_buffer_open := true


func _init():
	load_templates()

func load_templates():
	template_function_call = read_file(TEMPLATE_FUNC)
	template_set_variable = read_file(TEMPLATE_SET)

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
#	tokenize_result.pretty_print()
	translate_tokens(tokenize_result.tokens)


func translate_tokens(tokens) -> Array:
	var gdscript_sources := []
	for token in tokens:
		update_identifier_buffer(token)
		process_token(token)
	
	return gdscript_sources


func process_token(token: Token):
	if not state:
		start_new_instruction(token)
	else:
		instruction_buffer.append(token)
		if (token.type == Tokens.LINEBREAK 
		  and opened_tokens.empty()):
			end_instruction()
			return
		continue_instruction(token)


func start_new_instruction(token: Token):
	assert(identifier_buffer.empty())
	assert(opened_tokens.empty())
	instruction_buffer.clear()
	match token.type:
		Tokens.STRING:
			current_instruction = DisplayText.new()
			current_instruction.text = token.text
			state = DISPLAY_TEXT
		_:
			current_instruction = null
			state = CALL_FUNCTION
	



func continue_instruction(token: Token):
	match state:
		UNKNOWN_INSTRUCTION:
			update_instruction_type(token)
			if state != UNKNOWN_INSTRUCTION:
				continue_instruction(token)
			else:
				buffer_token(token)
		DISPLAY_TEXT:
			continue_display_text_instruction(token)
		DISPLAY_TEXT_WITH_PARAMS:
			continue_display_text_params_instruction(token)
		SET_VARIABLE:
			continue_set_variable_instruction(token)
		CALL_FUNCTION:
			continue_call_function_instruction(token)


func update_identifier_buffer(token: Token):
	identifier_is_settable = (token.type == Tokens.IDENTIFIER)
	
	var token_opens_buffer = (
		token.type == Tokens.OPERATOR
		or token.type == Tokens.ASSIGN
		or token.type == Tokens.LINEBREAK
		or token.type == Tokens.COMMA
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


func continue_display_text_instruction(token: Token):
	assert(token.type == Tokens.STRING_MULTILINE_CONT)
	assert(current_instruction is DisplayText)
	current_instruction.text += token.text.replace("\n", "\\n")

func continue_display_text_params_instruction(token: Token):
	pass

func continue_set_variable_instruction(token: Token):
	pass

func continue_call_function_instruction(token: Token):
	if token.type == Tokens.DOT and not opened_tokens:
		state = UNKNOWN_INSTRUCTION
		pass
	pass


func update_instruction_type(token: Token):
	match token.type:
		Tokens.ASSIGN:
			assert(identifier_is_settable)
			start_set_variable_instruction(token)
		Tokens.COLON:
			start_display_text_params_instruction(token)
		Tokens.COMMA:
			start_display_text_params_instruction(token)
	pass


func start_set_variable_instruction(token: Token):
	assert(token.type == Tokens.OPERATOR)
	assert(current_instruction == null)
	current_instruction = SetVariable.new()
	current_instruction.operator = token.text
	for t in unknown_instruction_buffer:
		current_instruction.target += t.text

func start_display_text_params_instruction(token: Token):
	current_instruction = DisplayText.new()
	current_instruction.params = ""
	for t in unknown_instruction_buffer:
		current_instruction.params += t.text
	state = DISPLAY_TEXT_WITH_PARAMS


func buffer_token(token: Token):
	unknown_instruction_buffer.append(token)


func flush_identifier_buffer():
	if identifier_buffer.empty():
		return
	
	var identifier: String = ""
	for t in identifier_buffer:
		identifier += t.text
	identifier_buffer.clear()
	print("Processing identifier: " + identifier)


func expand_identifier(token: Token):
	assert(token.type == Tokens.IDENTIFIER)
	pass


func end_instruction():
	state = ""
