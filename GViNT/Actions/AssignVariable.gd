extends "res://GViNT/Actions/BaseAction.gd"

const GvintVariable = preload("res://GViNT/GvintVariable.gd")


func execute():
	assert(
		get_target_object() is GvintVariable, 
		invalid_set_target_error()
	)
	var target: GvintVariable = get_target_object()
	target.value = get_new_value()
	emit_signal("action_completed")


func undo():
	get_target_object().undo_last_change()
	emit_signal("undo_completed")


#todo: error messages based on metadata embedded by the translator
func invalid_set_target_error():
	return "invalid set target - must be GvintVariable"


func get_target_object():
	
	pass


func get_new_value():
	
	pass

