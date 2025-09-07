@tool
extends RefCounted


const Token = Gvint.Token

var result := Gvint.ParseResult.new()

var _position: int = 0
var _source_tokens: Array[Token]
var _current_token: Token

static func parse_text(source_code: String) -> Gvint.ParseResult:
	var parser = Gvint.Parser.new()
	var tokenize_result := Gvint.Tokenizer.tokenize_text(source_code)
	if tokenize_result.errors:
		parser.result.errors = tokenize_result.errors as Array[Gvint.TranspileError]
		return parser.result
	
	if not tokenize_result.tokens:
		return parser.result
	
	parser._source_tokens = tokenize_result.tokens
	parser._current_token = parser._source_tokens.front()
	
	while not (
		parser._end_reached()
		or parser._has_errors()
	):
		var instruction = parser._process_next_instruction()
		if instruction:
			parser.result.instructions.append(instruction)
	
	return parser.result


static func update_parse_result(
	parse_result: Gvint.ParseResult,
	update_source_code: String,
	update_from_line: int,
	line_count_change: int
) -> Gvint.ParseResult:
	# start by duplicating the existing instructions
	var new_result := Gvint.ParseResult.new()
	new_result.instructions = parse_result.instructions.duplicate()
	
	# parse the update source code
	var parse_update_result = parse_text(update_source_code)
	# if there's errors, don't proceed with the update
	if parse_update_result.errors:
		new_result.errors = parse_update_result.errors
		for error in new_result.errors:
			error.line += update_from_line
		return new_result
	
	# remove instructions that had their source code lines modified or removed
	var update_source_code_line_count: int = update_source_code.count("\n") + 1
	for line_index in range(
			update_from_line,
			update_from_line + update_source_code_line_count - line_count_change
	):
		var removed_instruction = new_result.get_instruction_on_line(line_index)
		if removed_instruction:
			new_result.instructions.erase(removed_instruction)
	
	# the updated instructions will be spliced into the instructions array
	# after the last instruction before the update source code block,
	# or at index 0 if there's no instructions before the update.
	# calculate that index:
	var updated_instructions_splice_index: int = 0
	var last_instruction_before_update: Gvint.ParseInstruction = null
	var i: int = update_from_line - 1
	while last_instruction_before_update == null and i >= 0:
		last_instruction_before_update = new_result.get_instruction_on_line(i)
		if last_instruction_before_update != null:
			updated_instructions_splice_index = new_result.instructions.find(last_instruction_before_update) + 1
		i -= 1
	
	# if lines were added or removed, adjust start_line & end_line on each instruction after the update
	if line_count_change != 0:
		for index in range(updated_instructions_splice_index, new_result.instructions.size()):
			new_result.instructions[index].start_line += line_count_change
			new_result.instructions[index].end_line += line_count_change
	
	# splice the updated instructions into new_result.instructions
	i = 0
	for instruction in parse_update_result.instructions:
		instruction.start_line += update_from_line
		instruction.end_line += update_from_line
		new_result.instructions.insert(updated_instructions_splice_index + i, instruction)
		i += 1
	
	return new_result


func _process_next_instruction() -> Gvint.ParseInstruction:
	_skip_linebreaks()
	if _end_reached():
		return null
	
	if _current_token.type == Token.KEYWORD_IF:
		return _process_if_condition()
	
	if not Token.is_beginning_of_expression(_current_token):
		_add_error()
		return null
	
	var instruction_start_line: int = _current_token.start_line
	var instruction_end_line: int = instruction_start_line
	var initial_expression := _process_expression()
	if not initial_expression:
		# return null on error
		return null
	
	var has_colon: bool = false
	var expressions_before_colon: Array[Gvint.ParseExpression] = [initial_expression]
	var expressions_after_colon: Array[Gvint.ParseExpression] = []
	var assignment_operator: Token = null
	var assignment_value: Gvint.ParseExpression = null
	
	var expecting_expression: bool = false
	var accept_colon: bool = true
	var accept_comma: bool = true
	var end_of_instruction_reached: bool = false
	
	while true:
		if end_of_instruction_reached:
			if expecting_expression:
				_add_error('Expected value expression, found: end of instruction.')
				return null
			if assignment_operator and assignment_value:
				var instruction = Gvint.ParseInstructionSetVariable.new()
				instruction.variable_identifier = expressions_before_colon[0].components[0]
				instruction.assignment_operator = assignment_operator
				instruction.value_expression = assignment_value
				instruction.start_line = instruction_start_line
				instruction.end_line = instruction_end_line
				return instruction
			elif not has_colon:
				if (
						expressions_before_colon.size() == 1
						and initial_expression.components.size() == 1
						and initial_expression.components[0] is Gvint.ParseCall
						and not initial_expression.has_grouping_parentheses
				):
					var instruction = Gvint.ParseInstructionCall.new()
					instruction.parse_call = initial_expression.components[0]
					instruction.start_line = instruction_start_line
					instruction.end_line = instruction_end_line
					return instruction
				else:
					var instruction = Gvint.ParseInstructionDisplayText.new()
					instruction.text_expressions = expressions_before_colon
					instruction.start_line = instruction_start_line
					instruction.end_line = instruction_end_line
					return instruction
			else:
				if expressions_after_colon.is_empty():
					_add_error('Expected value expression after colon (":"), found: end of instruction.')
					return null
				else:
					var instruction = Gvint.ParseInstructionDisplayText.new()
					instruction.param_expressions = expressions_before_colon
					instruction.text_expressions = expressions_after_colon
					instruction.start_line = instruction_start_line
					instruction.end_line = instruction_end_line
					return instruction
		
		if _end_reached():
			end_of_instruction_reached = true
			continue
		else:
			instruction_end_line = _current_token.end_line
		
		if Token.is_assignment_operator(_current_token):
			var has_assignable_identifier: bool = false
			if (
					expressions_before_colon.size() == 1
					and initial_expression.components.size() == 1
					and initial_expression.components[0] is Gvint.ParseIdentifier
					and (not initial_expression.has_grouping_parentheses)
					and (not has_colon)
			):
				var identifier: Gvint.ParseIdentifier = initial_expression.components[0]
				var identifier_first_component: Gvint.ParseNode = identifier.components.front()
				var identifier_last_token: Token = identifier.components.back()
				if identifier_first_component is Token:
					if (
							identifier_first_component.type == Token.IDENTIFIER
							# builtin function names are valid variable identifiers in GDScript.
							# (technically, so are type specifiers - but allowing type specifiers
							# as variable names would introduce ambiguities into the parsing process
							# that would be very difficult to deal with, so those are not allowed)
							or identifier_first_component.type == Token.BUILTIN_FUNC
							or (identifier_first_component.type == Token.ENGINE_SINGLETON
							and identifier.components.size() > 1)
					):
						has_assignable_identifier = true
				else:
					if (
							identifier_last_token.type == Token.BRACKET_CLOSE
							or identifier_last_token.type == Token.IDENTIFIER
					):
						has_assignable_identifier = true
			
			if has_assignable_identifier:
				assignment_operator = _current_token
				expecting_expression = true
				accept_colon = false
				accept_comma = false
				_advance()
				continue
			else:
				_add_error('Assignable identifier not found before assignment operator; invalid "set variable" instruction.')
				return null
		elif Token.is_beginning_of_expression(_current_token):
			if expecting_expression:
				if assignment_operator:
					if assignment_value != null:
						_add_error()
						return null
					var expression := _process_expression()
					if not expression:
						return null
					assignment_value = expression
				else:
					var expression := _process_expression()
					if not expression:
						# return null on error
						return null
					if has_colon:
						expressions_after_colon.append(expression)
					else:
						expressions_before_colon.append(expression)
				expecting_expression = false
				if not has_colon:
					accept_colon = true
				accept_comma = true
				continue
			else:
				_add_error()
				return null
		
		match _current_token.type:
			Token.LINEBREAK:
				end_of_instruction_reached = true
				continue
			Token.COMMA:
				if assignment_value != null:
					_add_error()
					return null
				if accept_comma:
					expecting_expression = true
					accept_colon = false
					accept_comma = false
					_advance()
					continue
				else:
					_add_error()
					return null
			Token.COLON:
				if assignment_value != null:
					_add_error()
					return null
				if accept_colon:
					has_colon = true
					expecting_expression = true
					accept_colon = false
					accept_comma = false
					_advance()
					continue
				else:
					_add_error()
					return null
			_:
				_add_error()
				return null
	
	return null


func _process_if_condition() -> Gvint.ParseInstructionIfCondition:
	var instruction_start_line: int = _current_token.start_line
	var instruction_end_line: int
	
	assert(_current_token.type == Token.KEYWORD_IF)
	_advance()
	var if_condition := Gvint.ParseInstructionIfCondition.new()
	var current_branch := Gvint.ParseInstructionConditionalBranch.new()
	var processing_else_branch: bool = false
	
	while true:
		if not processing_else_branch:
			if not Token.is_beginning_of_expression(_current_token):
				_add_error()
				return null
			var condition_expression := _process_expression()
			if not condition_expression:
				# return null on error
				return null
			current_branch.condition = condition_expression
		
		if _end_reached() or _current_token.type != Token.BRACE_OPEN:
			_add_error('Expected opening brace ("{") after conditional statement.')
			return null
		_advance()
		
		if _end_reached():
			_add_error('Expected instruction or closing brace ("}"), found: end of parsing.')
			return null
		
		while _current_token.type != Token.BRACE_CLOSE:
			# the tokenizer always adds a linebreak at the end of the file,
			# therefore current token will never be null here; checking it is safe
			# and this if condition will always be triggered just before end is reached
			if _current_token.type == Token.LINEBREAK:
				_skip_linebreaks()
				if _end_reached():
					_add_error('Expected instruction or closing brace ("}"), found: end of parsing.')
					return null
				continue
			var next_instruction := _process_next_instruction()
			if not next_instruction:
				# return null on error
				return null
			current_branch.instructions.append(next_instruction)
		assert(_current_token and _current_token.type == Token.BRACE_CLOSE)
		instruction_end_line = _current_token.end_line
		_advance()
		if_condition.branches.append(current_branch)
		_skip_linebreaks()
		if processing_else_branch or _end_reached():
			break
		match _current_token.type:
			Token.KEYWORD_ELIF:
				if processing_else_branch:
					_add_error('Expected end of conditional statement after "else" branch.')
					return null
				current_branch = Gvint.ParseInstructionConditionalBranch.new()
				_advance()
				continue
			Token.KEYWORD_ELSE:
				if processing_else_branch:
					_add_error('Expected end of conditional statement after "else" branch.')
					return null
				processing_else_branch = true
				current_branch = Gvint.ParseInstructionConditionalBranch.new()
				_advance()
				continue
			_:
				break
	
	if_condition.start_line = instruction_start_line
	if_condition.end_line = instruction_end_line
	return if_condition


func _process_expression(skip_ternary_if_linebreaks: bool = false) -> Gvint.ParseExpression:
	var expression = Gvint.ParseExpression.new()
	var expecting_value: bool = true
	var expecting_type_specifier: bool = false
	var expecting_operator: bool = false
	var has_open_parenthesis: bool = false
	var has_close_parenthesis: bool = false
	
	while Token.is_unary_operator(_current_token):
		expression.prefix_unary_operators.append(_current_token)
		_advance()
	
	if _current_token.type == Token.PARENTHESIS_OPEN:
		has_open_parenthesis = true
		skip_ternary_if_linebreaks = true
		_advance()
	
	while true:
		if _end_reached():
			if expecting_value:
				_add_error('Expected value expression, found: end of statement.')
			break
		
		if Token.is_binary_operator(_current_token):
			if has_close_parenthesis:
				var sub_expression = expression
				expression = Gvint.ParseExpression.new()
				expression.components.append(sub_expression)
				has_open_parenthesis = false
				has_close_parenthesis = false
				expecting_value = false
				expecting_operator = true
			if expecting_operator:
				var operator_was_keyword_is: bool = (_current_token.type == Token.KEYWORD_IS)
				if operator_was_keyword_is:
					expecting_type_specifier = true
				expecting_operator = false
				expecting_value = true
				expression.components.append(_current_token)
				_advance()
				# allow "is not" operator for "foo is not SomeType"
				if (
						(not _end_reached())
						and operator_was_keyword_is
						and _current_token.type == Token.KEYWORD_NOT
				):
					expression.components.append(_current_token)
					_advance()
				continue
			else:
				# "+" and "-" are simultaneously binary and unary operators
				if Token.is_unary_operator(_current_token):
					expression.components.append(_current_token)
					_advance()
					continue
				else:
					_add_error('Expected value expression, found operator: "%s".' % _current_token)
					return null
		elif Token.is_unary_operator(_current_token):
			if expecting_value:
				expression.components.append(_current_token)
				_advance()
				continue
			else:
				# allow "not in" operator for "foo not in some_container"
				if _current_token.type == Token.KEYWORD_NOT:
					expression.components.append(_current_token)
					_advance()
					if (
							(not _end_reached())
							and _current_token.type == Token.KEYWORD_IN
					):
						expecting_operator = false
						expecting_value = true
						expression.components.append(_current_token)
						_advance()
						continue
					else:
						_add_error('Expected "in" after "not" in content-test operator.')
						return null
				_add_error('Expected binary operator or end of expression, found unary operator: "%s".' % _current_token)
				return null
		elif Token.is_assignment_operator(_current_token):
			if expecting_value:
				_add_error('Expected value expression, found assignment operator: "%s".' % _current_token)
			break
		
		match _current_token.type:
			Token.LINEBREAK:
				if has_open_parenthesis:
					if has_close_parenthesis:
						break
					else:
						_advance()
						continue
				else:
					if expecting_value:
						_add_error('Expected value expression, found: end of expression.')
					break
			Token.LITERAL, Token.BUILTIN_CONST:
				if expecting_value:
					expression.components.append(_current_token)
					expecting_value = false
					expecting_operator = true
					_advance()
					continue
				else:
					_add_error(
						('Unexpected literal value "%s".' % _current_token)
						if _current_token.type == Token.LITERAL
						else ('Unexpected builtin constant: "%s".' % _current_token)
					)
					return null
			Token.IDENTIFIER,\
			Token.ENGINE_SINGLETON,\
			Token.TYPE,\
			Token.BUILTIN_TYPE,\
			Token.BUILTIN_FUNC:
				if expecting_value:
					var identifier_or_call = _process_compound_identifier()
					if identifier_or_call:
						var is_standalone_type_specifier: bool = (
								identifier_or_call is Gvint.ParseIdentifier
								and identifier_or_call.components.size() == 1
								and (identifier_or_call.components[0].type == Token.TYPE
								or identifier_or_call.components[0].type == Token.BUILTIN_TYPE)
						)
						if expecting_type_specifier:
							if not is_standalone_type_specifier:
								_add_error('Expected type specifier after type checking operator.')
								return null
							expecting_type_specifier = false
						elif (
								is_standalone_type_specifier
								and identifier_or_call.components[0].type == Token.BUILTIN_TYPE
						):
							_add_error('Builtin type cannot be used as a name on its own.')
						expecting_value = false
						expecting_operator = true
						expression.components.append(identifier_or_call)
						continue
					else:
						# return null on error
						return null
				else:
					_add_error(
						('Unexpected identifier: "%s".' % _current_token)
						if _current_token.type == Token.IDENTIFIER
						else ('Unexpected engine singleton: "%s".' % _current_token)
						if _current_token.type == Token.ENGINE_SINGLETON
						else ('Unexpected type specifier: "%s".' % _current_token)
						if (_current_token.type == Token.TYPE or _current_token.type == Token.BUILTIN_TYPE)
						else ('Unexpected builtin function name: "%s".' % _current_token)
					)
					return null
			Token.KEYWORD_IF:
				if not expecting_operator:
					_add_error('Unexpected keyword "if" in expression.')
					return null
				
				expression.components.append(_current_token)
				_advance()
				
				if skip_ternary_if_linebreaks:
					_skip_linebreaks()
				var ternary_if_condition_expression = _process_expression(skip_ternary_if_linebreaks)
				if not ternary_if_condition_expression:
					# return null on error
					return null
				expression.components.append(ternary_if_condition_expression)
				
				if skip_ternary_if_linebreaks:
					_skip_linebreaks()
				if _current_token.type != Token.KEYWORD_ELSE:
					_add_error('Expected "else" after ternary operator condition.')
					return null
				expression.components.append(_current_token)
				_advance()
				
				if skip_ternary_if_linebreaks:
					_skip_linebreaks()
				if not Token.is_beginning_of_expression(_current_token):
					_add_error('Expected value expression after "else".')
				var else_value_expression = _process_expression(skip_ternary_if_linebreaks)
				if not else_value_expression:
					# return null on error
					return null
				expression.components.append(else_value_expression)
				
				expecting_value = false
				expecting_operator = true
				continue
			Token.BRACE_OPEN:
				if expecting_value:
					var dictionary := _process_dictionary()
					if dictionary:
						expecting_value = false
						expecting_operator = true
						expression.components.append(dictionary)
						continue
					else:
						# return null on error
						return null
				else:
					# allow brace open after expression for conditional statements
					break
			Token.BRACKET_OPEN:
				if expecting_value:
					var array := _process_array()
					if array:
						expecting_value = false
						expecting_operator = true
						expression.components.append(array)
						continue
					else:
						# return null on error
						return null
				# allow indexing expressions with grouping parentheses
				elif (has_open_parenthesis and has_close_parenthesis):
					var identifier_or_call := _process_compound_identifier(expression)
					expression = Gvint.ParseExpression.new()
					expression.components.append(identifier_or_call)
					has_open_parenthesis = false
					has_close_parenthesis = false
					expecting_operator = true
					expecting_value = false
				else:
					_add_error()
					return null
			Token.PARENTHESIS_OPEN:
				if expecting_value:
					var sub_expression = _process_expression()
					if sub_expression:
						expecting_value = false
						expecting_operator = true
						expression.components.append(sub_expression)
						continue
					else:
						# return null on error
						return null
				else:
					_add_error()
					return null
			Token.PARENTHESIS_CLOSE:
				if has_close_parenthesis:
					break
				if has_open_parenthesis:
					if not expecting_value:
						has_close_parenthesis = true
						expecting_operator = true
						expression.has_grouping_parentheses = true
						_advance()
					else:
						_add_error('Expected value expression, found closing parenthesis (")").')
						return null
				else:
					break
			Token.BRACKET_CLOSE,\
			Token.BRACE_CLOSE,\
			Token.COLON,\
			Token.COMMA:
				if has_open_parenthesis and not has_close_parenthesis:
					_add_error('Expected closing parenthesis (")") or continuation of expression, found: "%s".' % _current_token)
				if expecting_value:
					_add_error('Expected value expression, found: "%s".' % _current_token)
				break
			Token.DOT:
				if (has_open_parenthesis and has_close_parenthesis):
					var identifier_or_call := _process_compound_identifier(expression)
					expression = Gvint.ParseExpression.new()
					expression.components.append(identifier_or_call)
					has_open_parenthesis = false
					has_close_parenthesis = false
					expecting_operator = true
					expecting_value = false
				else:
					_add_error()
					return null
			_:
				_add_error()
				return null
	
	if _has_errors():
		return null
	else:
		return expression


func _process_compound_identifier(prefix_call_or_expression: Gvint.ParseNode = null) -> Gvint.ParseNode:
	var identifier := Gvint.ParseIdentifier.new()
	if prefix_call_or_expression:
		identifier.components.append(prefix_call_or_expression)
	var accept_dot: bool = true if prefix_call_or_expression else false
	var expecting_identifier: bool = false if prefix_call_or_expression else true
	var accept_type_or_singleton: bool = false if prefix_call_or_expression else true
	var accept_builtin_func: bool = false if prefix_call_or_expression else true
	var accept_parenthesis_open: bool = false
	var accept_bracket_open: bool = true if prefix_call_or_expression else false
	
	while true:
		if _end_reached():
			if expecting_identifier:
				_add_error("Expected identifier or method name, found: end of statement.")
			break
		
		if Token.is_binary_operator(_current_token):
			if expecting_identifier:
				_add_error('Expected identifier or method name, found operator "%s".' % _current_token)
			break
		elif Token.is_assignment_operator(_current_token):
			if expecting_identifier:
				_add_error('Expected identifier or method name, found assignment operator "%s".' % _current_token)
			break
		
		match _current_token.type:
			Token.LINEBREAK:
				if expecting_identifier:
					_add_error('Expected identifier or method name, found: linebreak.')
				break
			Token.IDENTIFIER:
				if expecting_identifier:
					identifier.components.append(_current_token)
					expecting_identifier = false
					accept_builtin_func = false
					accept_type_or_singleton = false
					accept_parenthesis_open = true
					accept_bracket_open = true
					accept_dot = true
					_advance()
					continue
				else:
					_add_error('Unexpected identifier: "%s".' % _current_token)
					return null
			Token.BUILTIN_FUNC:
				if accept_builtin_func:
					identifier.components.append(_current_token)
					expecting_identifier = false
					accept_builtin_func = false
					accept_type_or_singleton = false
					accept_parenthesis_open = true
					accept_bracket_open = true
					_advance()
					continue
				else:
					_add_error('Unexpected builtin function name: "%s".' % _current_token)
					return null
			Token.TYPE,\
			Token.BUILTIN_TYPE:
				if accept_type_or_singleton:
					identifier.components.append(_current_token)
					expecting_identifier = false
					accept_builtin_func = false
					accept_type_or_singleton = false
					accept_parenthesis_open = true
					accept_dot = true
					_advance()
					continue
				else:
					_add_error('Unexpected type specifier: "%s".' % _current_token)
					return null
			Token.ENGINE_SINGLETON:
				if accept_type_or_singleton:
					identifier.components.append(_current_token)
					expecting_identifier = false
					accept_builtin_func = false
					accept_type_or_singleton = false
					accept_dot = true
					_advance()
					continue
				else:
					_add_error('Unexpected engine singleton: "%s".' % _current_token)
					return null
			Token.DOT:
				if accept_dot:
					identifier.components.append(_current_token)
					expecting_identifier = true
					accept_builtin_func = true
					accept_parenthesis_open = false
					accept_bracket_open = false
					accept_dot = false
					_advance()
					continue
				else:
					_add_error()
					return null
			Token.BRACKET_OPEN:
				if accept_bracket_open:
					identifier.components.append(_current_token)
					_advance()
					
					_skip_linebreaks()
					if _end_reached():
						_add_error('Expected expression, found: end of statement.')
						return null
					
					var index_expression = _process_expression(true)
					if not index_expression:
						# return null on error
						return null
					identifier.components.append(index_expression)
					
					_skip_linebreaks()
					if _end_reached():
						_add_error('Expected closing bracket ("]"), found: end of statement.')
						return null
					
					if _current_token.type == Token.BRACKET_CLOSE:
						identifier.components.append(_current_token)
						_advance()
						continue
					else:
						_add_error('Expected closing bracket ("]"), found token: "%s".' % _current_token)
						return null
				else:
					_add_error('Unxpected opening bracket ("[").')
					return null
			Token.PARENTHESIS_OPEN:
				if accept_parenthesis_open:
					return _process_call(identifier)
				else:
					_add_error('Unxpected opening parenthesis ("(").')
					return null
			Token.COLON,\
			Token.COMMA,\
			# allow "x not in y" operator
			Token.KEYWORD_NOT,\
			Token.PARENTHESIS_CLOSE,\
			Token.BRACE_OPEN,\
			Token.BRACE_CLOSE,\
			Token.BRACKET_CLOSE:
				break
			_:
				_add_error()
				return null
	
	if _has_errors():
		return null
	else:
		return identifier


func _process_call(prefix_identifier: Gvint.ParseIdentifier) -> Gvint.ParseNode:
	var parse_call = Gvint.ParseCall.new()
	parse_call.identifier = prefix_identifier
	
	assert(_current_token.type == Token.PARENTHESIS_OPEN)
	_advance()
	
	var expecting_expression: bool = true
	var accept_close_parenthesis: bool = true
	var has_close_parenthesis: bool = false
	
	while true:
		if _end_reached():
			if not has_close_parenthesis:
				_add_error(
					'Expected value expression, found: end of statement.' if expecting_expression
					else 'Expected comma (",") or closing parenthesis (")"), found: end of statement.'
				)
			break
		
		if Token.is_beginning_of_expression(_current_token):
			if expecting_expression:
				var expression := _process_expression(true)
				if not expression:
					# return null on error
					return null
				parse_call.param_expressions.append(expression)
				expecting_expression = false
				accept_close_parenthesis = true
				continue
			elif has_close_parenthesis:
				match _current_token.type:
					# "+" and "-" are simulateneously unary operators 
					# (and a valid beginning of expression) and binary operators,
					# so should check for them here and break on them
					# to allow "some_call() + [...]" expressions
					Token.PLUS,\
					Token.MINUS,\
					# break on "not" to allow "some_call() not in some_container" expressions
					Token.KEYWORD_NOT,\
					# break on "{" for if conditions as in "if some_call() { [...]"
					Token.BRACE_OPEN:
						break
					Token.BRACKET_OPEN:
						return _process_compound_identifier(parse_call)
					_:
							_add_error()
							return null
			else:
				_add_error('Expected comma (",") or closing parenthesis (")"), found: "%s".' % _current_token)
				return null
		elif Token.is_binary_operator(_current_token):
			if has_close_parenthesis:
				break
			else:
				_add_error('Unexpected operator: "%s".' % _current_token)
				return null
		
		match _current_token.type:
			Token.LINEBREAK:
				if has_close_parenthesis:
					break
				else:
					_advance()
					continue
			Token.PARENTHESIS_CLOSE:
				if not accept_close_parenthesis:
					_add_error('Expected value expression, found closing parenthesis (")").')
					return null
				if has_close_parenthesis:
					break
				else:
					has_close_parenthesis = true
					expecting_expression = false
					_advance()
					continue
			Token.COMMA:
				if has_close_parenthesis:
					break
				if not expecting_expression:
					expecting_expression = true
					accept_close_parenthesis = false
					_advance()
					continue
				else:
					_add_error('Expected value expression, found comma (",").')
					return null
			Token.DOT:
				if has_close_parenthesis:
					return _process_compound_identifier(parse_call)
				else:
					_add_error()
					return null
			Token.BRACKET_OPEN:
				if has_close_parenthesis:
					return _process_compound_identifier(parse_call)
				else:
					_add_error()
					return null
			Token.COLON,\
			Token.BRACE_OPEN,\
			Token.BRACE_CLOSE,\
			Token.BRACKET_CLOSE:
				if has_close_parenthesis:
					break
				else:
					_add_error()
					return null
			_:
				_add_error()
				return null
	
	if _has_errors():
		return null
	else:
		return parse_call


func _process_dictionary() -> Gvint.ParseNode:
	var dictionary := Gvint.ParseDictionary.new()
	
	assert(_current_token.type == Token.BRACE_OPEN)
	_advance()
	
	while true:
		if _end_reached():
			_add_error('Expected dictionary entry or closing brace ("}"), found: end of statement.')
			return null
		
		if _current_token.type == Token.BRACE_CLOSE:
			_advance()
			break
		
		if not dictionary.expressions_pairs.is_empty():
			if _current_token.type == Token.COMMA:
				_advance()
				continue
			else:
				_add_error('Expected comma or closing brace ("}") after key-value pair, found: "%s".' % _current_token)
				return null
		
		if not Token.is_beginning_of_expression(_current_token):
			_add_error('Expected dictionary key, found: "%s".' % _current_token)
			return null
		
		var key_value_pair := Gvint.ParseExpressionPair.new()
		
		key_value_pair.key = _process_expression(true)
		if not key_value_pair.key:
			# return null on error
			return null
		
		if _end_reached():
			_add_error('Expected colon (":") after dictionary key, found: end of statement.')
			return null
		if _current_token.type != Token.COLON:
			_add_error('Expected colon (":") after dictionary key, found: "%s".' % _current_token)
			return null
		_advance()
		
		if _end_reached():
			_add_error("Expected dictionary value, found: end of statement.")
			return null
		if not Token.is_beginning_of_expression(_current_token):
			_add_error('Expected dictionary value, found: "%s".' % _current_token)
			return null
		
		key_value_pair.value = _process_expression(true)
		if not key_value_pair.value:
			# return null on error
			return null
		dictionary.expressions_pairs.append(key_value_pair)
	
	if _has_errors():
		return null
	else:
		if (
				_current_token.type == Token.DOT
				or _current_token.type == Token.BRACKET_OPEN
		):
			var expression := Gvint.ParseExpression.new()
			expression.components.append(dictionary)
			return _process_compound_identifier(expression)
		else:
			return dictionary


func _process_array() -> Gvint.ParseArray:
	var array := Gvint.ParseArray.new()
	
	assert(_current_token.type == Token.BRACKET_OPEN)
	_advance()
	
	while true:
		if _end_reached():
			_add_error('Expected value expression or closing bracket ("]"), found: end of statement.')
			return null
		
		if Token.is_beginning_of_expression(_current_token):
			var expression = _process_expression(true)
			if not expression:
				# return null on error
				return null
			array.expressions.append(expression)
			_skip_linebreaks()
			if _end_reached():
				_add_error('Expected comma (",") or closing bracket ("]"), found: end of statement.')
				return null
			match _current_token.type:
				Token.BRACKET_CLOSE:
					_advance()
					break
				Token.COMMA:
					_advance()
					continue
				_:
					_add_error('Expected comma (",") or closing bracket ("]"), found: "%s".' % _current_token)
					return null
		
		match _current_token.type:
			Token.LINEBREAK:
				_skip_linebreaks()
				continue
			Token.BRACKET_CLOSE:
				break
			_:
				_add_error()
				return null
	
	if _has_errors():
		return null
	else:
		if (
				_current_token.type == Token.DOT
				or _current_token.type == Token.BRACKET_OPEN
		):
			var expression := Gvint.ParseExpression.new()
			expression.components.append(array)
			return _process_compound_identifier(expression)
		else:
			return array


func _add_error(text: String = "") -> void:
	if text == "":
		text = 'Unexpected token: "%s".' % _current_token
	var error := Gvint.ParseError.new()
	if _end_reached():
		error.line = _source_tokens.back().end_line
		error.column = _source_tokens.back().end_column
	else:
		error.line = _current_token.start_line
		error.column = _current_token.start_column
	error.text = text.replace('"\n"', "linebreak")
	result.errors.append(error)


func _has_errors() -> bool:
	return not result.errors.is_empty()


func _end_reached():
	return _position >= _source_tokens.size()


func _skip_linebreaks() -> void:
	while _current_token and _current_token.type == Token.LINEBREAK:
		_advance()


func _advance():
	_position += 1
	if not _end_reached():
		_current_token = _source_tokens[_position]
	else:
		_current_token = null
