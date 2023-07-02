
const STATEMENT_PREFIX = "Statement_"

const BASE = """extends Reference

{statement_class_definitions}


static func create_context() -> GvintContext:
	var context = GvintContext.new()
	context.source_filename = "{source_filename}"
	context.statements = {statement_class_names}
	return context
"""


const SET_WITH_UNDO = """class Statement_{statement_id}:
	static func get_id():
		return "{statement_id}"
	
	static func evaluate(runtime: GvintRuntimeStateful):
		var target = {target}
		assert(target is GvintVariable)
		var value = {value}
		if value is GDScriptFunctionState:
			value = yield(value, "completed")
		target.value {operator} value
	
	static func undo(runtime: GvintRuntimeStateful):
		var target = {target}
		assert(target is GvintVariable)
		target.undo_last_change()
"""

const SET_WITHOUT_UNDO = """class Statement_{statement_id}:
	static func get_id():
		return "{statement_id}"
	
	static func evaluate(runtime: GvintRuntimeStateless):
		var value = {value}
		if value is GDScriptFunctionState:
			value = yield(value, "completed")
		{target} {operator} value
"""

const CALL_FUNCTION_WITH_UNDO = """class Statement_{statement_id}:
	static func get_id():
		return "{statement_id}"
	
	static func evaluate(runtime: GvintRuntimeStateful):
		var target = {target}
		assert(target.has_method("{method}"))
		var result = target.callv("{method}", [{params}])
		if result is GDScriptFunctionState:
			yield(result, "completed")
	
	static func undo(runtime: GvintRuntimeStateful):
		var target = {target}
		if target.has_method("{undo_method}"):
			var result = target.call("{undo_method}")
			if result is GDScriptFunctionState:
				yield(result, "completed")
"""

const CALL_FUNCTION_WITHOUT_UNDO = """class Statement_{statement_id}:
	static func get_id():
		return "{statement_id}"
	
	static func evaluate(runtime: GvintRuntimeStateless):
		var target = {target}
		assert(target.has_method("{method}"))
		var result = target.callv("{method}", [{params}])
		if result is GDScriptFunctionState:
			yield(result, "completed")
"""

const CONDITIONAL_STATEMENT = """class Statement_{statement_id}:
	static func get_id():
		return "{statement_id}"
{nested_statements}
{context_getters}
	static func evaluate_conditional(runtime):
		if {main_condition}:
			return create_branch0_context()
{sub_conditions}

"""

const SUB_CONDITION = """		{keyword} {condition}:
			return create_{branch_id}_context()
"""

const CONDITIONAL_CONTEXT_GETTER = """static func create_{branch_id}_context() -> GvintContext:
	var context = GvintContext.new()
	context.source_filename = "{source_filename}"
	context.statements = {statement_class_names}
	return context
"""

