extends "res://GViNT/Translator/Templates/BaseAction.gd"

static func execute(runtime):
	runtime.callv("do_a_thing", [runtime.some_param,"asdf",123])
	runtime.emit_signal("action_completed")

static func undo(runtime):
	runtime.call("undo_do_a_thing")
	runtime.emit_signal("undo_completed")
