extends Reference

const CALL_FUNCTION = """extends "res://GViNT/Translator/Templates/BaseAction.gd"

static func execute_gvint_action(runtime):
	var result = {target}.callv("{method}", [{params}])
	if result is GDScriptFunctionState:
		yield(result, "completed")

static func undo_gvint_action(runtime):
	var result = {target}.call("{undo_method}")
	if result is GDScriptFunctionState:
		yield(result, "completed")
"""

const SET_VARIABLE = """extends "res://GViNT/Translator/Templates/BaseAction.gd"

static func execute_gvint_action(runtime):
	assert({target} is GvintVariable)
	{target}.value {operator} {value}
	runtime.emit_signal("action_completed")

static func undo_gvint_action(runtime):
	{target}.undo_last_change()
	runtime.emit_signal("undo_completed")
"""
