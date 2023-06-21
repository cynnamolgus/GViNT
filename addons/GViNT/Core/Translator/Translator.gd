extends Reference



const Templates = preload("res://addons/GViNT/Core/Translator/TranslationTemplates.gd")

const GvintUtils = preload("res://addons/GViNT/Core/Utils.gd")
const GvintConfig = preload("res://addons/GViNT/Core/Config.gd")

const Tokenizer = preload("res://addons/GViNT/Core/Translator/Tokenizer/Tokenizer.gd")
const TokenizeResult = preload("res://addons/GViNT/Core/Translator/Tokenizer/TokenizeResult.gd")
const Token = preload("res://addons/GViNT/Core/Translator/Tokenizer/Token.gd")

const Tokens = preload("res://addons/GViNT/Core/Translator/Tokenizer/Tokens.gd")
const Chars = preload("res://addons/GViNT/Core/Translator/Characters.gd")

const Statement = preload("res://addons/GViNT/Core/Translator/Statements/Statement.gd")
const SetVariable = preload("res://addons/GViNT/Core/Translator/Statements/SetVariable.gd")
const CallFunction = preload("res://addons/GViNT/Core/Translator/Statements/CallFunction.gd")
const DisplayText = preload("res://addons/GViNT/Core/Translator/Statements/DisplayText.gd")
const IfCondition = preload("res://addons/GViNT/Core/Translator/Statements/IfCondition.gd")
const ConditionalBranch = preload("res://addons/GViNT/Core/Translator/Statements/ConditionalBranch.gd")
const EndConditional = preload("res://addons/GViNT/Core/Translator/Statements/EndConditional.gd")


var tokenizer := Tokenizer.new()

var unpaired_tokens := []

var unpaired_braces: int = 0


var current_statement
var statements := []

var statement_buffer := []
var identifier_buffer := []

var identifier_is_settable := false
var identifier_buffer_open := true

var nested_conditionals = 0
var last_statement_was_conditional := false


func read_file(file: String) -> String:
	var content: String
	var f := File.new()
	f.open(file, File.READ)
	content = f.get_as_text()
	f.close()
	return content


func clear():
	tokenizer.clear()
	current_statement = null
	statement_buffer.clear()
	identifier_buffer.clear()
	identifier_is_settable = false
	identifier_buffer_open = true


func translate_file(file: String, config: GvintConfig) -> String:
	var source_code := read_file(file)
	var gdscript_code := translate_source_code(source_code, config)
	return gdscript_code


func translate_source_code(source_code: String, config: GvintConfig) -> String:
	clear()
	var tokenize_result := tokenizer.tokenize_text(source_code)
	
	var gdscript_code := translate_tokens(tokenize_result.tokens, config)
	assert(statement_buffer.empty())
	assert(identifier_buffer.empty())
	return gdscript_code


func translate_tokens(tokens: Array, config: GvintConfig) -> String:
	parse_statements(tokens, config)
	collapse_conditionals()
	
	var index: int = 0
	var statement_class_names_list = []
	var statement_class_definitions = ""
	for s in statements:
		s.statement_id = str(index)
		statement_class_names_list.append(Templates.STATEMENT_PREFIX + s.statement_id)
		statement_class_definitions += s.to_string() + "\n"
		index += 1
	
	var statement_class_names = GvintUtils.pretty_print_array(statement_class_names_list)
	
	
	var result = Templates.BASE.format({
		"statement_class_definitions": statement_class_definitions,
		"statement_class_names": statement_class_names
	})
	
	return result


func parse_statements(tokens: Array, config: GvintConfig):
	statements = []
	for t in tokens:
		if (unpaired_braces == nested_conditionals) and t.type == Tokens.CLOSE_BRACE:
			statements.append(EndConditional.new())
			nested_conditionals -= 1
			update_paired_tokens(t)
			continue
		update_paired_tokens(t)
		update_identifier_buffer(t, config)
		if statement_buffer and token_ends_statement(t):
			var statement = end_statement(config)
			statements.append(statement)
		elif (t.type != Tokens.LINEBREAK
		  and t.type != Tokens.END_OF_FILE):
			statement_buffer.append(t)


func collapse_conditionals():
	var conditional_stack = []
	var collapsed_statements = []
	
	for s in statements:
		if s is IfCondition:
			conditional_stack.push_back(s)
			continue
		
		if s is ConditionalBranch:
			assert(collapsed_statements.back() is ConditionalBranch)
			
			var cond = collapsed_statements.pop_back()
			assert(cond is IfCondition)
			conditional_stack.push_back(cond)
			
			conditional_stack.back().branches.append(s)
			conditional_stack.back().current_branch += 1
			continue
		
		if s is EndConditional:
			assert(conditional_stack)
			if conditional_stack.back().current_branch > 0:
				conditional_stack.back().current_branch -= 1
			
			var nested_conditional = conditional_stack.pop_back()
			if conditional_stack:
				var parent_conditional = conditional_stack.back()
				var target_branch = parent_conditional.branches[parent_conditional.current_branch]
				target_branch.branch_statements.push_back(nested_conditional)
			else:
				collapsed_statements.push_back(nested_conditional)
			continue
		
		if conditional_stack:
			var cond: IfCondition = conditional_stack.back()
			cond.branches[cond.current_branch].branch_statements.push_back(s)
		else:
			collapsed_statements.push_back(s)
	
	statements = collapsed_statements


func token_ends_statement(token: Token) -> bool:
	if statement_buffer.front().type in Tokens.CONDITIONALS:
		return (
			token.type == Tokens.LINEBREAK 
			and unpaired_tokens.back() == Tokens.OPEN_BRACE
		) or token.type == Tokens.END_OF_FILE
	else:
		return (
			token.type == Tokens.LINEBREAK 
			and (unpaired_braces <= nested_conditionals)
		) or token.type == Tokens.END_OF_FILE


func update_identifier_buffer(token: Token, config: GvintConfig):
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
		or token.type in Tokens.CONDITIONALS
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
	
	if token.type == Tokens.OPEN_BRACE:
		unpaired_braces += 1
	if token.type == Tokens.CLOSE_BRACE:
		assert(unpaired_braces)
		unpaired_braces -= 1
	
	if token.type in Tokens.OPENING_TOKENS:
		unpaired_tokens.append(token.type)
	elif unpaired_tokens:
		if token.type == Tokens.CLOSING_TOKENS[unpaired_tokens.back()]:
			unpaired_tokens.pop_back()


func flush_identifier_buffer(config: GvintConfig):
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


func end_statement(config: GvintConfig) -> Statement:
	current_statement = instantiate_statement_from_buffer()
	current_statement.construct_from_tokens(statement_buffer)
	statement_buffer.clear()
	
	# todo: generalize script translation config
	if current_statement is DisplayText:
		current_statement.target = config.display_text_target
		current_statement.method = config.display_text_method
		current_statement.undo_method = config.undo_method_prefix + config.display_text_method
	elif current_statement is CallFunction:
		current_statement.undo_method = (
			config.undo_method_prefix
			+ current_statement.method 
		)
	
	return current_statement


func instantiate_statement_from_buffer():
	assert(statement_buffer)
	
	var instance
	
	var first_token = statement_buffer.front()
	last_statement_was_conditional = true
	match first_token.type:
		Tokens.KEYWORD_IF:
			instance = IfCondition.new()
			instance.template = Templates.CONDITIONAL_STATEMENT
			nested_conditionals += 1
			return instance
		Tokens.KEYWORD_ELSE:
			nested_conditionals += 1
			instance = ConditionalBranch.new()
			return instance
		Tokens.KEYWORD_ELIF:
			nested_conditionals += 1
			instance = ConditionalBranch.new()
			return instance
	last_statement_was_conditional = false
	
	var colons := 0
	var assignments := 0
	var dict_level := 0
	for t in statement_buffer:
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
		instance = DisplayText.new()
		instance.has_params = true
		instance.template = Templates.CALL_FUNCTION
		return instance
	elif statement_buffer[0].type == Tokens.STRING:
		instance = DisplayText.new()
		instance.template = Templates.CALL_FUNCTION
		
		return DisplayText.new()
	if assignments:
		assert(assignments == 1)
		instance = SetVariable.new()
		instance.template = Templates.SET_WITHOUT_UNDO
		return instance
	
	if instance == null:
		instance = CallFunction.new()
		instance.template = Templates.CALL_FUNCTION
	
	assert(instance)
	return instance

