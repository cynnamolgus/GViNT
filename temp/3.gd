extends "res://GViNT/Translator/Templates/BaseAction.gd"

static func execute(runtime):
	assert(runtime.some_variable is GvintVariable)
	runtime.some_variable.value = "hello"
	runtime.emit_signal("action_completed")

static func undo(runtime):
	runtime.some_variable.undo_last_change()
	runtime.emit_signal("undo_completed")
