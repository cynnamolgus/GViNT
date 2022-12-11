extends "res://GViNT/Translator/Instructions/Instruction.gd"



var params_tokens := []
var params_string := ""

var text := ""
var target := ""
var method := ""
var undo_method := ""



func _init():
	template = Templates.CALL_FUNCTION


func construct_from_tokens(tokens: Array):
	var has_params := false
	if tokens[0].type == Tokens.STRING:
		construct_from_string_literal(tokens)
	else:
		construct_from_params_and_text(tokens)


func construct_from_string_literal(tokens: Array):
	for t in tokens:
		assert(t.type == Tokens.STRING
		  or t.type == Tokens.STRING_MULTILINE_CONT)
		text += t.text


func construct_from_params_and_text(tokens: Array):
	var params_ended = false
	for t in tokens:
		if t.type == Tokens.COLON:
			assert(not params_ended)
			params_ended = true
			continue
		if not params_ended:
			params_tokens.append(t)
		else:
			assert(t.type == Tokens.INLINE_TEXT
			  or t.type == Tokens.STRING
			  or t.type == Tokens.STRING_MULTILINE_CONT)
			text += t.text


func to_gdscript():
	for t in params_tokens:
		params_string += t.text
	return template.format({
		"target": target,
		"method": method,
		"undo_method": undo_method,
		"params": "[\"\"\"" + text + "\"\"\", [" + params_string + "]]"
	})
