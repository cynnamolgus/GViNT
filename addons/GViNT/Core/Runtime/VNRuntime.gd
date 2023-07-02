tool
class_name VNRuntime extends "res://addons/GViNT/Core/Runtime/GvintRuntime.gd"


const FINISHED = "FINISHED"

var _context_spawning_statements := {}
var _yielding_statements := {}

var _last_yielded_funcstate: GDScriptFunctionState


func _init():
	_config_id = "vn"


func create_runtime_var(identifier: String, default_value = null):
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


func start(script_filename: String):
	assert(_config_id)
	assert(_config_id in GvintScripts.configs)
	
	var is_running = _current_context != null
	
	script_filename = _expand_source_filename(script_filename)
	var context_factory = GvintScripts.load_script(script_filename, _config_id)
	_enter_context(context_factory.create_context())
	if not is_running:
		runtime_variables.clear()
		_init_runtime_vars()
		_on_script_execution_starting()
		emit_signal("script_execution_starting", self)
		execute_until_yield_or_finished()

func stop():
	if _last_yielded_funcstate:
		_last_yielded_funcstate.disconnect("completed", self, "_on_last_yielded_statement_completed")
		_last_yielded_funcstate = null
		_context_stack.clear()
		_current_context = null
		emit_signal("script_execution_interrupted")


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


func _enter_context(ctx: GvintContext):
	if _current_context:
		_mark_current_statement_as_context_spawning()
	._enter_context(ctx)




func _execute_next_statement():
	while _current_context.is_finished():
		_exit_context()
		if not _current_context:
			return FINISHED
	
	var script_statement = _current_context.next_statement()
	var result
	if script_statement.new().has_method("evaluate_conditional"):
		var conditional_context = script_statement.evaluate_conditional(self)
		_enter_context(conditional_context)
	else:
		result = script_statement.evaluate(self)
		if result is GDScriptFunctionState:
			_mark_current_statement_as_yielding()
			_last_yielded_funcstate = result
			_last_yielded_funcstate.connect("completed", self, "_on_last_yielded_statement_completed")
			return result
	return null


func execute_until_yield_or_finished():
	var result
	while true:
		if result is String:
			if result == FINISHED:
				emit_signal("script_execution_finished")
				break
		result = _execute_next_statement()
		if result is GDScriptFunctionState:
			break


func _undo_until_yield():
	var reached_yielding_statement = false
	
	if _yielding_statements.size() < 2:
		return false
	if _is_current_statement_first_yielding_statement():
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



func _on_last_yielded_statement_completed():
	_last_yielded_funcstate.disconnect("completed", self, "_on_last_yielded_statement_completed")
	_last_yielded_funcstate = null
	if _current_context:
		execute_until_yield_or_finished()


func _is_current_statement_yielding():
	if not _current_context.source_filename in _yielding_statements:
		return false
	var statements = _yielding_statements[_current_context.source_filename]
	var current_statement_id = _current_context.current_statement().get_id()
	return current_statement_id in statements

func _is_current_statement_first_yielding_statement():
	if _current_context.source_filename != _yielding_statements.keys().front():
		return false
	var statements = _yielding_statements[_current_context.source_filename]
	var current_statement_id = _current_context.current_statement().get_id()
	return current_statement_id == statements.front()

func _mark_current_statement_as_yielding():
	if not _current_context.source_filename in _yielding_statements:
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
	
	var context_stack = []
	for ctx in _context_stack:
		context_stack.append(ctx.to_json_object())
	context_stack.append(_current_context.to_json_object())
	
	var result = {
		"context_stack": context_stack,
		"yielding_statements": _yielding_statements,
		"context_spawning_statements": _context_spawning_statements,
		"state_data": state_data,
	}
	
	GvintUtils.save_file(savefile_path, JSON.print(result, "  "))


func load_state(savefile_path: String):
	stop()
	var json_data = GvintUtils.load_json_dict(savefile_path)
	assert(json_data)
	_validate_savestate_data(json_data)
	_yielding_statements = json_data.yielding_statements
	_context_spawning_statements = json_data.context_spawning_statements
	_restore_context_stack(json_data.context_stack)
	_load_state(json_data.state_data)


func _validate_savestate_data(data: Dictionary):
	
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
		
		if context_data.source_filename == previous_context_source_filename:
			context = previous_context_last_statement.call("create_" + split_id[-2] + "_context")
		else:
			context = GvintScripts.load_script(context_data.source_filename, _config_id).create_context()
		
		context.current_statement_index = int(split_id[-1])
		
		previous_context_last_statement = context.current_statement()
		previous_context_source_filename = context.source_filename
		
		context_data = data.pop_back()
	
	assert(_context_stack.size() >= 1)
	_current_context = _context_stack.pop_back()


func _save_state() -> Dictionary:
	return {}

func _load_state(saved_data: Dictionary):
	pass

