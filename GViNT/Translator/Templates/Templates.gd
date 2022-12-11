extends Reference

const CALL_FUNCTION = """extends "res://GViNT/Translator/Templates/BaseAction.gd"

static func execute(runtime):
	{target}.callv("{method}", [{params}])
	runtime.emit_signal("action_completed")

static func undo(runtime):
	{target}.call("{undo_method}")
	runtime.emit_signal("undo_completed")
"""

const SET_VARIABLE = """extends "res://GViNT/Translator/Templates/BaseAction.gd"

static func execute(runtime):
	assert({target} is GvintVariable)
	{target}.value {operator} {value}
	runtime.emit_signal("action_completed")

static func undo(runtime):
	{target}.undo_last_change()
	runtime.emit_signal("undo_completed")
"""
