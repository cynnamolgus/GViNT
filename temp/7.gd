extends "res://GViNT/Translator/Templates/BaseAction.gd"

static func execute(runtime):
	assert(runtime.do_a_thing().some_property is GvintVariable)
	runtime.do_a_thing().some_property.value = runtime.some_method(runtime.i,[runtime.a,runtime.b,runtime.c],{"key":runtime.value}).some_property
	runtime.emit_signal("action_completed")

static func undo(runtime):
	runtime.do_a_thing().some_property.undo_last_change()
	runtime.emit_signal("undo_completed")
