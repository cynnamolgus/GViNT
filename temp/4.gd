extends "res://GViNT/Translator/Templates/BaseAction.gd"

static func execute(runtime):
	runtime.callv("display_text", ["""It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged.""", []])
	runtime.emit_signal("action_completed")

static func undo(runtime):
	runtime.call("undo_display_text")
	runtime.emit_signal("undo_completed")
