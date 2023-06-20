
const STATEMENT_PREFIX = "Statement_"

const BASE = """extends Reference

{statement_class_definitions}


static func create_context() -> GvintContext:
	var context = GvintContext.new()
	context.source_filename = "{source_filename}"
	context.instructions = {statement_class_names}
	return context
"""


const SET_WITH_UNDO = """class Statement_{statement_id}:
	static func evaluate(runtime: GvintRuntime):
		var target = {target}
		assert(target is GvintVariable)
		target.value {operator} {value}
	
	static func undo(runtime: GvintRuntime):
		var target = {target}
		target.undo_last_change()

"""

const SET_WITHOUT_UNDO = """class Statement_{statement_id}:
	static func evaluate(runtime: GvintRuntime):
		{target} {operator} {value}

"""

const CALL_FUNCTION = """class Statement_{statement_id}:
	static func evaluate(runtime: GvintRuntime):
		var target = {target}
		assert(target.has_method("{method}"))
		assert(target.has_method("{undo_method}"))
		var result = target.callv("{method}", [{params}])
		if result is GDScriptFunctionState:
			yield(result, "completed")
	
	static func undo(runtime: GvintRuntime):
		var target = {target}
		var result = target.call("{undo_method}")
		if result is GDScriptFunctionState:
			yield(result, "completed")

"""

const CONDITIONAL_STATEMENT = """class Statement_{statement_id}:
	{nested_intructions}
	
	{context_getters}
	
	static func evaluate(runtime: GvintRuntime):
		if {main_condition}:
			return get_branch0_context()
		{sub_conditions}

"""

const SUB_CONDITION = """		{keyword} {condition}:
			return get_{branch_id}_context()
"""

const CONDITIONAL_CONTEXT_GETTER = """	static func create_{branch_id}_context() -> GvintContext:
		var context = GvintContext.new()
		context.source_filename = "{source_filename}"
		context.instructions = {statement_list}
		return context
	
"""

