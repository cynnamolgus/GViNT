class_name GvintRuntime extends Node



signal action_completed
signal undo_completed



const GvintUtils = preload("res://addons/GViNT/Core/Utils.gd")


var runtime_variables := {}
var context_stack := []
var current_context: GvintContext



func _get(property):
	var calling_method = GvintUtils.check_calling_method()
	var called_by_runtime_action = (
		calling_method == "execute_script_instruction"
		or calling_method == "undo_script_instruction"
	)
	if called_by_runtime_action:
		if property in runtime_variables:
			return runtime_variables[property]
		else:
			return init_runtime_var(property)

func _set(property, value):
	if property in runtime_variables:
		runtime_variables[property] = value
		return true
	return false


func _ready():
	execute_script("test")
	pass


func execute_script(file: String):
	var new_context := GvintScripts.load_script(file)
	var result
	for instruction in new_context.instructions:
		result = instruction.execute_script_instruction(self)
		if result is GDScriptFunctionState:
			yield(result, "completed")


func init_runtime_var(identifier: String):
	if not identifier in runtime_variables:
		runtime_variables[identifier] = GvintVariable.new()
	return runtime_variables[identifier]


func display_text(test, params):
	print(str(params) + ": " + test)
	yield(get_tree().create_timer(0.25), "timeout")

func undo_display_text():
	pass

func get_some_value():
	return 42

func do_a_thing():
	print(runtime_variables.foo)

func undo_do_a_thing():
	pass


