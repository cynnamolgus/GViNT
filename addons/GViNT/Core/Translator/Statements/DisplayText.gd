extends "res://addons/GViNT/Core/Translator/Statements/Statement.gd"



var params_tokens := []
var params_string := ""

var text := ""
var target := ""
var method := ""
var undo_method := ""

var has_params: bool = false

func _init():
	template = ScriptTemplates.CALL_FUNCTION


func construct_from_tokens(tokens: Array):
	if has_params:
		construct_from_params_and_text(tokens)
	else:
		construct_from_string_literal(tokens)


func construct_from_string_literal(tokens: Array):
	for t in tokens:
		assert(t.type == Tokens.STRING
		  or t.type == Tokens.STRING_MULTILINE_CONT)
		text += t.text.trim_prefix('"').trim_suffix('"')


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
			if t.type == Tokens.INLINE_TEXT:
				assert(t == tokens.back())
				text = t.text
			else:
				assert(t.type == Tokens.STRING
				  or t.type == Tokens.STRING_MULTILINE_CONT)
				text += t.text.trim_prefix('"').trim_suffix('"')


func _to_string():
	for t in params_tokens:
		params_string += t.text
	return template.format({
		"statement_id": statement_id,
		"target": target,
		"method": method,
		"undo_method": undo_method,
		"params": "\"\"\"" + text + "\"\"\", [" + params_string + "]"
	})
