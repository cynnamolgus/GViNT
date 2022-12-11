extends "res://GViNT/Translator/Templates/BaseAction.gd"

static func execute(runtime):
	runtime.callv("display_text", ["""Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.""", [runtime.foo,runtime.bar,"literal",randi()]])
	runtime.emit_signal("action_completed")

static func undo(runtime):
	runtime.call("undo_display_text")
	runtime.emit_signal("undo_completed")
