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
const IDLE = "IDLE"
const UNKNOWN_INSTRUCTION = "UNKNOWN"
const CALL_FUNCTION = "CALL_FUNCTION"
const SET_VARIABLE = "SET_VARIABLE"
const DISPLAY_TEXT = "DISPLAY_TEXT"
const DISPLAY_TEXT_WITH_PARAMS = "DISPLAY_TEXT_PARAMS"

var template_function_call := ""
var template_set_variable := ""

var tokenizer := Tokenizer.new()

var state := IDLE
var unpaired_tokens := []

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
	return translate_tokens(tokenize_result.tokens)


func translate_tokens(tokens) -> Array:
	var gdscript_sources := []
	
	for t in tokens:
		update_paired_tokens(t)
		update_identifier_buffer(t)
		if token_ends_instruction(t) and instruction_buffer:
			var gdscript_instruction = end_instruction()
			gdscript_sources.append(gdscript_instruction)
		else:
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
	pass


func update_instruction(token: Token):
	if instruction_buffer.empty():
		assert(unpaired_tokens.empty())
	
	instruction_buffer.append(token)


func flush_identifier_buffer():
	if identifier_buffer.empty():
		return
	
	#todo: proper identifier expansion. placeholder for testing.
	identifier_buffer[0].text = "runtime." + identifier_buffer[0].text
	identifier_buffer.clear()


func end_instruction():
	var InstructionType = DisplayText
	current_instruction = InstructionType.new()
	current_instruction.construct_from_tokens(instruction_buffer)
	instruction_buffer.clear()
	
	current_instruction.target = "runtime"
	current_instruction.method = "display_text"
	current_instruction.undo_method = "undo_display_text"
	
	return current_instruction.to_gdscript()



