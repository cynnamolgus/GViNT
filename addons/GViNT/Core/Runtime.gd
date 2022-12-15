class_name GvintRuntime extends Node



signal action_completed
signal undo_completed



const GvintUtils = preload("res://addons/GViNT/Core/Utils.gd")

export(String, FILE, "*.story") var autostart_script := ""

var _regex: RegEx

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
	_init_pascal_case_regex()
	register_children(self)
	runtime_variables.erase(to_snake_case(name))
	if autostart_script:
		execute_script(autostart_script)


func _init_pascal_case_regex():
	_regex = RegEx.new()
	_regex.compile('((?<=[a-z0-9])[A-Z]|(?!^)[A-Z](?=[a-z]))')


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


func to_snake_case(identifier: String):
	return _regex.sub(identifier, "_$1", true).to_lower()


func register_children(node: Node):
	var snake_case_name = to_snake_case(node.name)
	if snake_case_name in runtime_variables:
		push_warning("Duplicate runtime node '" + node.name + "'")
	if not snake_case_name.begins_with("_"):
		runtime_variables[snake_case_name] = node
	for child in node.get_children():
		register_children(child)


