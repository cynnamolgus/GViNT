extends "res://GViNT/Translator/Templates/BaseAction.gd"

static func execute(runtime):
	assert(runtime.i is GvintVariable)
	runtime.i.value = 0
	runtime.emit_signal("action_completed")

static func undo(runtime):
	runtime.i.undo_last_change()
	runtime.emit_signal("undo_completed")
