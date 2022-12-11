extends "res://GViNT/Translator/Instructions/Instruction.gd"



var target_tokens := []
var params_tokens := []

var target_string := ""
var params_string := ""

var method: String
var undo_method: String



func _init():
	template = Templates.CALL_FUNCTION


func construct_from_tokens(tokens: Array):
	assert(len(tokens) >= 3)
	var i: int = len(tokens) - 2
	var nested_parentheses = 0
	var processed_params = false
	var processed_method = false
	while i >= 0:
		if not processed_params:
			params_tokens.append(tokens[i])
			if tokens[i].type == Tokens.OPEN_PARENTHESIS:
				if nested_parentheses == 0:
					processed_params = true
				else: 
					nested_parentheses -= 1
			if tokens[i].type == Tokens.CLOSE_PARENTHESIS:
				nested_parentheses += 1
		elif not processed_method:
			assert(tokens[i].type == Tokens.IDENTIFIER)
			method = tokens[i].text
			processed_method = true
		else:
			target_tokens.append(tokens[i])
		
		i -= 1
	
	params_tokens.pop_back() # remove first open parenthesis
	params_tokens.invert()
	if target_tokens.empty():
		var method_helper = method
		method = Array(method.split(".")).back()
		target_string = method_helper.trim_suffix("." + method)
	else:
		target_tokens.invert()
	
	pass


func to_gdscript():
	for t in target_tokens:
		target_string += t.text
	for t in params_tokens:
		params_string += t.text
	return template.format({
		"target": target_string,
		"method": method,
		"undo_method": undo_method,
		"params": params_string
	})
