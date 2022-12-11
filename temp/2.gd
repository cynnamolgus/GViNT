extends "res://GViNT/Translator/Templates/BaseAction.gd"

static func execute(runtime):
	runtime.callv("display_text", ["""""", [runtime.foo]])
	runtime.emit_signal("action_completed")

static func undo(runtime):
	runtime.call("undo_display_text")
	runtime.emit_signal("undo_completed")
