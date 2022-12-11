extends "res://GViNT/Translator/Templates/BaseAction.gd"

static func execute(runtime):
	runtime.callv("display_text", ["""It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, 
and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.""", [runtime.foo]])
	runtime.emit_signal("action_completed")

static func undo(runtime):
	runtime.call("undo_display_text")
	runtime.emit_signal("undo_completed")
