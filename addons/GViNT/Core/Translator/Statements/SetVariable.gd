extends "res://addons/GViNT/Core/Translator/Statements/Statement.gd"



var target_tokens := []
var value_tokens := []

var target_string := ""
var value_string := ""
var operator: String


func construct_from_tokens(tokens: Array):
	var assignment_processed := false
	for t in tokens:
		if not assignment_processed:
			if t.type == Tokens.ASSIGN:
				operator = t.text
				assignment_processed = true
			else:
				target_tokens.append(t)
		else:
			value_tokens.append(t)


func _to_string():
	for t in target_tokens:
		target_string += t.text
	for t in value_tokens:
		value_string += t.text
	return template.format({
		"statement_id": statement_id,
		"target": target_string,
		"operator": operator,
		"value": value_string,
	})
