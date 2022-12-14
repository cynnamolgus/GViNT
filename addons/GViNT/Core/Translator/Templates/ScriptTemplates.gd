extends Reference

const CALL_FUNCTION = """extends Reference

static func execute_script_instruction(runtime: GvintRuntime):
	var target = {target}
	assert(target.has_method("{method}"))
	assert(target.has_method("{undo_method}"))
	var result = target.callv("{method}", [{params}])
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

static func undo_script_instruction(runtime: GvintRuntime):
	{target}.undo_last_change()
"""

const LOADER_INSTRUCTION = "const Instruction_{instruction_index} = preload(\"{instruction_filename}\")"

const LOADER = """extends Reference

{instruction_preloads}

static func get_context() -> GvintContext:
	var context = GvintContext.new()
	context.source_filename = "{source_filename}"
	context.instructions = {instruction_list}
	return context
"""
