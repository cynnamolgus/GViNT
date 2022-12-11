extends "res://GViNT/Translator/Instructions/Instruction.gd"



var target_tokens := []
var value_tokens := []

var target_string := ""
var value_string := ""



func _init():
	template = Templates.SET_VARIABLE


func construct_from_tokens(tokens: Array):
	pass


func to_gdscript():
	for t in target_tokens:
		target_string += t.text
	for t in value_tokens:
		value_string += t.text
	return template.format({
		"target": value_string,
		"value": value_string
	})
