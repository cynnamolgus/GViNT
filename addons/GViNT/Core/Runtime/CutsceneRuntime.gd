tool
class_name CutsceneRuntime extends "res://addons/GViNT/Core/Runtime/GvintRuntime.gd"

func _init():
	if Engine.editor_hint and not config_id:
		config_id = "cutscene"

func start(script_filename: String):
	var context_factory = GvintScripts.load_script(script_filename, config_id)
	_enter_context(context_factory.create_context())
	if not is_running:
		_run_until_finished()

func _run_until_finished():
	is_running = true
	var result
	var script_statement
	while current_context and is_running:
		script_statement = current_context.next_statement()
		if script_statement.new().has_method("evaluate_conditional"):
			var conditional_context = script_statement.evaluate_conditional(self)
			_enter_context(conditional_context)
		else:
			result = script_statement.evaluate(self)
			if result is GDScriptFunctionState:
				yield(result, "completed")
		while current_context.is_finished():
			_exit_context()
	if is_running:
		emit_signal("script_execution_completed")
	else:
		emit_signal("script_execution_interrupted")
	is_running = false

func init_runtime_var(identifier: String, default_value = null):
	if not identifier in runtime_variables:
		runtime_variables[identifier] = default_value
	return runtime_variables[identifier]

func _set_runtime_var_value(identifier: String, value):
	runtime_variables[identifier] = value

func display_text(text: String, params: Array):
	print(str(params) + ": " + text)
	yield(get_tree().create_timer(1.0), "timeout")

