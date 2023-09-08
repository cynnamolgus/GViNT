class_name GvintRuntimeStateless extends Node


signal script_execution_starting
signal script_execution_yielded
signal script_execution_finished
signal script_execution_interrupted


const GvintUtils = preload("res://addons/GViNT/Core/Utils.gd")

const FINISHED = "FINISHED"


export(String, FILE) var autostart_script := ""
export(String, DIR) var default_script_directory: String = "res://Story"
export var default_script_extension: String = ".txt"

var _config_id = "stateless"

var runtime_variables := {}
var _context_stack := []
var _current_context: GvintContext

var _last_yielded_funcstate: GDScriptFunctionState


func _get(property):
	var calling_method = GvintUtils.check_calling_method()
	var called_by_runtime_action = (
		calling_method == "evaluate"
		or calling_method == "evaluate_conditional"
		or calling_method == "undo"
	)
	if called_by_runtime_action:
		if property in runtime_variables:
			return runtime_variables[property]
		else:
			return create_runtime_variable(property)


func _set(property, value):
	var calling_method = GvintUtils.check_calling_method()
	var called_by_runtime_action = (
		calling_method == "evaluate"
		or calling_method == "evaluate_conditional"
		or calling_method == "undo"
	)
	
	if called_by_runtime_action:
		if not property in runtime_variables:
			create_runtime_variable(property)
	
	if property in runtime_variables:
		_set_runtime_var_value(property, value)
		return true
	return false


func create_runtime_variable(identifier: String, default_value = null):
	if not identifier in runtime_variables:
		runtime_variables[identifier] = default_value
	return runtime_variables[identifier]


func _set_runtime_var_value(identifier: String, value):
	runtime_variables[identifier] = value



func _ready():
	if autostart_script and not Engine.editor_hint:
		start(autostart_script)


func start(script_filename: String):
	assert(_config_id)
	assert(_config_id in GvintScripts.configs)
	
	var is_running = _current_context != null
	
	script_filename = _expand_source_filename(script_filename)
	var context_factory = GvintScripts.load_script(script_filename, _config_id)
	_enter_context(context_factory.create_context())
	if not is_running:
		runtime_variables.clear()
		_on_script_execution_starting()
		emit_signal("script_execution_starting", self)
		execute_until_yield_or_finished()


func stop():
	if _last_yielded_funcstate:
		_last_yielded_funcstate.disconnect("completed", self, "_on_last_yielded_statement_completed")
		_last_yielded_funcstate = null
	
	if _current_context:
		_context_stack.clear()
		_current_context = null
		_on_script_execution_interrupted()
		emit_signal("script_execution_interrupted")


func _expand_source_filename(source_filename):
	if not source_filename.begins_with("res://"):
		source_filename = default_script_directory  + "/" + source_filename
	if not "." in source_filename:
		source_filename += default_script_extension
	return source_filename


func _enter_context(ctx: GvintContext):
	if _current_context:
		_context_stack.push_back(_current_context)
	_current_context = ctx

func _exit_context():
	assert(_current_context)
	if _context_stack:
		_current_context = _context_stack.pop_back()
	else:
		_current_context = null


func execute_until_yield_or_finished():
	var result
	while true:
		if result is String:
			if result == FINISHED:
				_on_script_execution_finished()
				emit_signal("script_execution_finished")
				break
		result = _execute_next_statement()
		if result is GDScriptFunctionState:
			emit_signal("script_execution_yielded", self)
			break


func _execute_next_statement():
	while _current_context.is_finished():
		_exit_context()
		if not _current_context:
			return FINISHED
	
	var script_statement = _current_context.next_statement()
	var result
	if script_statement.new().has_method("evaluate_conditional"):
		var conditional_context = script_statement.evaluate_conditional(self)
		if conditional_context:
			_enter_context(conditional_context)
	else:
		result = script_statement.evaluate(self)
		if result is GDScriptFunctionState:
			_on_current_statement_yielded()
			_last_yielded_funcstate = result
			_last_yielded_funcstate.connect("completed", self, "_on_last_yielded_statement_completed")
			return result
	return null


func _on_last_yielded_statement_completed():
	_last_yielded_funcstate.disconnect("completed", self, "_on_last_yielded_statement_completed")
	_last_yielded_funcstate = null
	if _current_context:
		execute_until_yield_or_finished()


func _on_current_statement_yielded():
	pass

func _on_script_execution_starting():
	pass

func _on_script_execution_finished():
	pass

func _on_script_execution_interrupted():
	pass

func display_text(text: String, params: Array):
	print(str(params) + ": " + text)
	yield(get_tree().create_timer(1.0), "timeout")

