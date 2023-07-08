tool
class_name GvintRuntimeStateful extends GvintRuntimeStateless

signal savestate_loaded


var _context_spawning_statements := {}
var _yielding_statements := {}

var _undo_limit_source_filename: String
var _undo_limit_statement_id: String

func _init():
	_config_id = "stateful"


func create_runtime_variable(identifier: String, default_value = null):
	if not identifier in runtime_variables:
		var runtime_var := GvintVariable.new()
		if default_value:
			runtime_var.value = default_value
		runtime_variables[identifier] = runtime_var
	return runtime_variables[identifier]


func _set_runtime_var_value(identifier: String, value):
	var runtime_var = runtime_variables[identifier]
	assert(runtime_var is GvintVariable)
	runtime_var.value = value


func step_backwards():
	if not _current_context:
		return
	if _current_context.current_statement_index == 0 and not _context_stack:
		return
	var undo_successful = _undo_until_yield()
	if undo_successful:
		if _last_yielded_funcstate:
			_last_yielded_funcstate.disconnect("completed", self, "_on_last_yielded_statement_completed")
			_last_yielded_funcstate = null
		execute_until_yield_or_finished()

func prevent_undo():
	_undo_limit_source_filename = _current_context.source_filename
	_undo_limit_statement_id = _current_context.current_statement().get_id()

func _enter_context(ctx: GvintContext):
	if _current_context:
		_mark_current_statement_as_context_spawning()
	._enter_context(ctx)



func _undo_until_yield():
	var reached_yielding_statement = false
	
	if _undo_limit_reached():
		return false
	
	var previous_statement = _current_context.current_statement()
	var entered_new_context = _undo_current_statement()
	if entered_new_context:
		previous_statement = _current_context.current_statement()
	else:
		if _current_context.current_statement_index == 0:
			_exit_context()
			_current_context.current_statement_index -= 1
			previous_statement = _current_context.current_statement()
		else:
			previous_statement = _current_context.previous_statement()
	
	while true:
		entered_new_context = _undo_current_statement()
		
		if entered_new_context:
			previous_statement = _current_context.current_statement()
			continue
		
		if _is_current_statement_yielding():
			_current_context.current_statement_index -= 1
			return true
		
		if _current_context.current_statement_index == 0:
			_exit_context()
			_current_context.previous_statement()
			if _is_current_statement_yielding():
				_current_context.current_statement_index -= 1
				return true
		else:
			previous_statement = _current_context.previous_statement()


func _undo_statement(statement):
	var entered_new_context = false
	if statement.new().has_method("undo"):
		statement.undo(self)
	if _context_spawning_statements:
		if statement in _context_spawning_statements:
			entered_new_context = true
			if statement.new().has_method("evaluate_conditional"):
				_enter_context(statement.evaluate_conditional(self))
			else:
				statement.evaluate(self)
			_current_context.current_statement_index = _current_context.statements.size() - 1
			assert(_current_context.current_statement_index >= -1)
	return entered_new_context


func _undo_current_statement():
	var entered_new_context = false
	var statement = _current_context.current_statement()
	if statement.new().has_method("undo"):
		statement.undo(self)
	if _is_current_statement_context_spawning():
		entered_new_context = true
		if statement.new().has_method("evaluate_conditional"):
			_enter_context(statement.evaluate_conditional(self))
		else:
			statement.evaluate(self)
		_current_context.current_statement_index = _current_context.statements.size() - 1
		assert(_current_context.current_statement_index >= -1)
	return entered_new_context


func _on_current_statement_yielded():
	_mark_current_statement_as_yielding()


func _is_current_statement_yielding():
	if not _current_context.source_filename in _yielding_statements:
		return false
	var statements = _yielding_statements[_current_context.source_filename]
	var current_statement_id = _current_context.current_statement().get_id()
	return current_statement_id in statements


func _undo_limit_reached():
	if _current_context.source_filename != _undo_limit_source_filename:
		return false
	var statements = _yielding_statements[_current_context.source_filename]
	var current_statement_id = _current_context.current_statement().get_id()
	return current_statement_id == _undo_limit_statement_id


func _mark_current_statement_as_yielding():
	if not _current_context.source_filename in _yielding_statements:
		if _yielding_statements.empty():
			_undo_limit_source_filename = _current_context.source_filename
			_undo_limit_statement_id = _current_context.current_statement().get_id()
		_yielding_statements[_current_context.source_filename] = []
	var statements = _yielding_statements[_current_context.source_filename]
	var current_statement_id = _current_context.current_statement().get_id()
	if not current_statement_id in statements:
		statements.append(current_statement_id)


func _is_current_statement_context_spawning():
	if not _current_context.source_filename in _context_spawning_statements:
		return false
	var statements = _context_spawning_statements[_current_context.source_filename]
	var current_statement_id = _current_context.current_statement().get_id()
	return current_statement_id in statements


func _mark_statement_as_context_spawning(source_filename: String, statement_id: String):
	if not source_filename in _context_spawning_statements:
		_context_spawning_statements[source_filename] = []
	var statements = _context_spawning_statements[source_filename]
	if not statement_id in statements:
		statements.append(statement_id)


func _mark_current_statement_as_context_spawning():
	if not _current_context.source_filename in _context_spawning_statements:
		_context_spawning_statements[_current_context.source_filename] = []
	var statements = _context_spawning_statements[_current_context.source_filename]
	var current_statement_id = _current_context.current_statement().get_id()
	if not current_statement_id in statements:
		statements.append(current_statement_id)


func save_state(savefile_path: String):
	var state_data = _save_state()
	
	var result = {
		"context_stack": _serialize_context_stack(),
		"runtime_variables": _serialize_runtime_variables(),
		"yielding_statements": _yielding_statements,
		"context_spawning_statements": _context_spawning_statements,
		"undo_limit": {
			"source_filename": _undo_limit_source_filename,
			"statement_id": _undo_limit_statement_id,
		},
		"state_data": state_data,
	}
	
	GvintUtils.save_file(savefile_path, JSON.print(result, "  "))


func _serialize_context_stack() -> Array:
	var context_stack = []
	for ctx in _context_stack:
		context_stack.append(ctx.to_json_object())
	context_stack.append(_current_context.to_json_object())
	return context_stack


func _serialize_runtime_variables() -> Dictionary:
	var result = {}
	
	for identifier in runtime_variables:
		if runtime_variables[identifier] is GvintVariable:
			result[identifier] = runtime_variables[identifier].serialize_state()
	
	return result



func load_state(savefile_path: String):
	stop()
	var json_data = GvintUtils.load_json_dict(savefile_path)
	_validate_savestate_data(json_data)
	_restore_context_stack(json_data.context_stack)
	_restore_runtime_variables(json_data.runtime_variables)
	_yielding_statements = json_data.yielding_statements
	_context_spawning_statements = json_data.context_spawning_statements
	_undo_limit_source_filename = json_data.undo_limit.source_filename
	_undo_limit_statement_id = json_data.undo_limit.statement_id
	_load_state(json_data.state_data)
	_on_script_execution_starting()
	emit_signal("savestate_loaded", json_data.state_data)


func _validate_savestate_data(data: Dictionary):
	assert(data)
	pass

func _restore_context_stack(data: Array):
	assert(_context_stack.empty())
	assert(_current_context == null)
	assert(data.size() >= 1)
	data.invert()
	
	var context_data = data.pop_back()
	var last_statement_id: String
	
	
	var split_id = context_data.last_statement_id.split("_")
	
	var script_context_factory = GvintScripts.load_script(context_data.source_filename, _config_id)
	var context: GvintContext = script_context_factory.create_context()
	
	context.current_statement_index = int(split_id[-1])
	
	var previous_context_last_statement = context.current_statement()
	var previous_context_source_filename = context.source_filename
	
	_context_stack.push_back(context)
	
	context_data = data.pop_back()
	while context_data:
		split_id = context_data.last_statement_id.split("_")
		var is_conditional = context_data.source_filename == previous_context_source_filename
		
		if is_conditional:
			context = previous_context_last_statement.call("create_" + split_id[-2] + "_context")
		else:
			context = GvintScripts.load_script(context_data.source_filename, _config_id).create_context()
		
		context.current_statement_index = int(split_id[-1])
		_context_stack.push_back(context)
		
		previous_context_last_statement = context.current_statement()
		previous_context_source_filename = context.source_filename
		
		context_data = data.pop_back()
	
	assert(_context_stack.size() >= 1)
	_current_context = _context_stack.pop_back()


func _restore_runtime_variables(savestate_data: Dictionary):
	runtime_variables.clear()
	for identifier in savestate_data:
		runtime_variables[identifier] = GvintVariable.new()
		runtime_variables[identifier].load_state(savestate_data[identifier])



func _save_state() -> Dictionary:
	return {}

func _load_state(savestate: Dictionary):
	pass

