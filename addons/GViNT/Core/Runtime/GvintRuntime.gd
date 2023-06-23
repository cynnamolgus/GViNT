class_name GvintRuntime extends Node


const GvintUtils = preload("res://addons/GViNT/Core/Utils.gd")

export(String, FILE) var autostart_script := ""
export(String) var config_id = ""


var runtime_variables := {}
var context_stack := []
var current_context: GvintContext

var is_running = false


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
			return init_runtime_var(property)

func _set(property, value):
	var calling_method = GvintUtils.check_calling_method()
	var called_by_runtime_action = (
		calling_method == "evaluate"
		or calling_method == "evaluate_conditional"
		or calling_method == "undo"
	)
	
	if called_by_runtime_action:
		if not property in runtime_variables:
			init_runtime_var(property)
	
	if property in runtime_variables:
		_set_runtime_var_value(property, value)
		return true
	return false


func _ready():
	if autostart_script:
		start(autostart_script)


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
		if current_context.is_finished():
			_exit_context()

func _enter_context(ctx: GvintContext):
	if current_context:
		context_stack.push_back(current_context)
	current_context = ctx

func _exit_context():
	assert(current_context)
	if context_stack:
		current_context = context_stack.pop_back()
	else:
		current_context = null
	
	if current_context:
		if current_context.is_finished():
			_exit_context()


func stop():
	assert(is_running)
	is_running = false
	context_stack.clear()
	current_context = null

func pause():
	assert(is_running)
	is_running = false

func resume():
	assert(current_context)
	assert(not is_running)
	_run_until_finished()


func init_runtime_var(identifier: String, default_value = null):
	if not identifier in runtime_variables:
		runtime_variables[identifier] = default_value
	return runtime_variables[identifier]

func _set_runtime_var_value(identifier: String, value):
	runtime_variables[identifier] = value

func serialize_state():
	# TODO
	pass


