extends "res://GViNT/Translator/Templates/BaseAction.gd"

static func execute(runtime):
	runtime.callv("display_text", ["""Lorem Ipsum is simply dummy text of the printing and typesetting industry.""", [runtime.foo]])
	runtime.emit_signal("action_completed")

static func undo(runtime):
	runtime.call("undo_display_text")
	runtime.emit_signal("undo_completed")