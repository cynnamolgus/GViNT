extends Node


signal script_execution_completed
signal script_execution_interrupted

const GvintUtils = preload("res://addons/GViNT/Core/Utils.gd")

export(String, FILE) var autostart_script := ""
export(String) var config_id = ""
export(String, DIR) var default_script_directory: String = "res://Story"
export var default_script_extension: String = ".txt"


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
	pass

func _expand_source_filename(source_filename):
	if not source_filename.begins_with("res://"):
		source_filename = default_script_directory + source_filename
	if not "." in source_filename:
		source_filename += default_script_extension
	return source_filename


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

func init_runtime_var(identifier: String, default_value = null):
	pass

func _set_runtime_var_value(identifier: String, value):
	pass


func serialize_state():
	# TODO
	pass

func restore_state(save_file_path: String):
	#TODO
	pass

