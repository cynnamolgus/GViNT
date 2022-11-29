class_name GvintRuntime extends Node

const Context = preload("res://GViNT/GvintContext.gd")

var runtime_variables := {}
var context_stack := []
var current_context: Context

var foo := "test"

func _get(property):
	if property in runtime_variables:
		return runtime_variables[property]


func next_action():
	
	pass


func undo_last_action():
	
	pass


