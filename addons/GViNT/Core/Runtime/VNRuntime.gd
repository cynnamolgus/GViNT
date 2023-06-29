tool
class_name VNRuntime extends "res://addons/GViNT/Core/Runtime/GvintRuntime.gd"


const FINISHED = "FINISHED"

var _context_spawning_statements := []
var _yielding_statements := []

var _last_yielded_funcstate: GDScriptFunctionState


func _init():
	if Engine.editor_hint:
		if not config_id:
			config_id = "vn"


func init_runtime_var(identifier: String, default_value = null):
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
	assert(config_id)
	assert(config_id in GvintScripts.configs)
	var is_running = _current_context != null
	var invoking_statement
	if is_running:
		invoking_statement = _current_context.current_statement()
	
	script_filename = _expand_source_filename(script_filename)
	var context_factory = GvintScripts.load_script(script_filename, config_id)
	_enter_context(context_factory.create_context())
	if not is_running:
		_execute_until_yield_or_finished()
	else:
		if not invoking_statement in _context_spawning_statements:
			_context_spawning_statements.push_back(invoking_statement)

func stop():
	assert(_last_yielded_funcstate)
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
		assert(_last_yielded_funcstate != null)
		_last_yielded_funcstate.disconnect("completed", self, "_on_last_yielded_statement_completed")
		_last_yielded_funcstate = null
		_execute_until_yield_or_finished()


func _enter_context(ctx: GvintContext):
	if _current_context:
		var current_statement = _current_context.current_statement()
		if not current_statement in _context_spawning_statements:
			_context_spawning_statements.push_back(current_statement)
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
			if not _yielding_statements.has(script_statement):
				_yielding_statements.append(script_statement)
			_last_yielded_funcstate = result
			_last_yielded_funcstate.connect("completed", self, "_on_last_yielded_statement_completed")
			return result
	return null


func _execute_until_yield_or_finished():
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
	if _current_context.last_executed_statement == _yielding_statements.front():
		return false
	
	var previous_statement = _current_context.current_statement()
	var entered_new_context = _undo_statement(previous_statement)
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
		entered_new_context = _undo_statement(previous_statement)
		
		if entered_new_context:
			previous_statement = _current_context.current_statement()
			continue
		
		if previous_statement in _yielding_statements:
			_current_context.current_statement_index -= 1
			return true
		
		if _current_context.current_statement_index == 0:
			_exit_context()
			if _current_context.previous_statement() in _yielding_statements:
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


func _on_last_yielded_statement_completed():
	_last_yielded_funcstate.disconnect("completed", self, "_on_last_yielded_statement_completed")
	_last_yielded_funcstate = null
	if _current_context:
		_execute_until_yield_or_finished()



