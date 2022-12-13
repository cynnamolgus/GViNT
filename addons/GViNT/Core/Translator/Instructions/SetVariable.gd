extends "res://addons/GViNT/Core/Translator/Instructions/Instruction.gd"



var target_tokens := []
var value_tokens := []

var target_string := ""
var value_string := ""
var operator: String


func _init():
	template = Templates.SET_VARIABLE


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


func to_gdscript():
	for t in target_tokens:
		target_string += t.text
	for t in value_tokens:
		value_string += t.text
	return template.format({
		"target": target_string,
		"operator": operator,
		"value": value_string,
	})
