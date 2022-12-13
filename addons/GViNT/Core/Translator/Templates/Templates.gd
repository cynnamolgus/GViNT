extends Reference

const CALL_FUNCTION = """extends Reference

static func execute_script_instruction(runtime: GvintRuntime):
	var result = {target}.callv("{method}", [{params}])
	if result is GDScriptFunctionState:
		yield(result, "completed")

static func undo_script_instruction(runtime: GvintRuntime):
	var result = {target}.call("{undo_method}")
	if result is GDScriptFunctionState:
		yield(result, "completed")
"""

const SET_VARIABLE = """extends Reference

static func execute_script_instruction(runtime: GvintRuntime):
	assert({target} is GvintVariable)
	{target}.value {operator} {value}
	runtime.emit_signal("action_completed")

static func undo_script_instruction(runtime: GvintRuntime):
	{target}.undo_last_change()
	runtime.emit_signal("undo_completed")
"""
