extends "res://GViNT/Translator/Instructions/Instruction.gd"



var target_tokens := []
var method_tokens := []
var params_tokens := []

var target_string := ""
var method_string := ""
var params_string := ""

var undo_method: String



func _init():
	template = Templates.CALL_FUNCTION


func construct_from_tokens(tokens: Array):
	pass


func to_gdscript():
	for t in target_tokens:
		target_string += t.text
	for t in method_tokens:
		method_string += t.text
	for t in params_tokens:
		params_string += t.text
	return template.format({
		"target": target_string,
		"method": method_string,
		"undo_method": undo_method,
		"params": params_string
	})
