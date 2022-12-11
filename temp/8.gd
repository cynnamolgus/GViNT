extends "res://GViNT/Translator/Templates/BaseAction.gd"

static func execute(runtime):
	assert(runtime.do_a_thing().some_property["foo"] is GvintVariable)
	runtime.do_a_thing().some_property["foo"].value = runtime.i
	runtime.emit_signal("action_completed")

static func undo(runtime):
	runtime.do_a_thing().some_property["foo"].undo_last_change()
	runtime.emit_signal("undo_completed")
