tool
class_name CutsceneRuntime extends "res://addons/GViNT/Core/Runtime/GvintRuntime.gd"


var _is_running = false


func _init():
	if Engine.editor_hint:
		if not config_id:
			config_id = "cutscene"


func init_runtime_var(identifier: String, default_value = null):
	if not identifier in runtime_variables:
		runtime_variables[identifier] = default_value
	return runtime_variables[identifier]


func _set_runtime_var_value(identifier: String, value):
	runtime_variables[identifier] = value


func start(script_filename: String):
	assert(config_id)
	assert(config_id in GvintScripts.configs)
	var context_factory = GvintScripts.load_script(script_filename, config_id)
	_enter_context(context_factory.create_context())
	if not _is_running:
		_run_until_finished()


func stop():
	_is_running = false
	_context_stack.clear()
	_current_context = null
	emit_signal("script_execution_interrupted")


func _run_until_finished():
	_is_running = true
	var result
	var script_statement
	while _current_context and _is_running:
		script_statement = _current_context.next_statement()
		if script_statement.new().has_method("evaluate_conditional"):
			var conditional_context = script_statement.evaluate_conditional(self)
			_enter_context(conditional_context)
		else:
			result = script_statement.evaluate(self)
			if result is GDScriptFunctionState:
				yield(result, "completed")
		while _current_context.is_finished():
			_exit_context()
	emit_signal("script_execution_finished")
	_is_running = false
