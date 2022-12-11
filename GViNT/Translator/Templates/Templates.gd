extends Reference

const CALL_FUNCTION = """extends "res://GViNT/Translator/Templates/BaseAction.gd"

static func execute(runtime):
	{target}.callv("{method}", {params})
	emit_signal("action_completed")

static func undo(runtime):
	{target}.call("{undo_method}")
	emit_signal("undo_completed")
"""

const SET_VARIABLE = """extends "res://GViNT/Translator/Templates/BaseAction.gd"

static func execute(runtime):
	{target}.value {operator} {value}
	emit_signal("action_completed")

static func undo(runtime):
	{target}.undo_last_change()
	emit_signal("undo_completed")
"""
